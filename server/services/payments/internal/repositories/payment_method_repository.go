package repositories

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"zviewer-payments-service/internal/models"

	"github.com/sirupsen/logrus"
)

// PaymentMethodRepository handles payment method data operations
type PaymentMethodRepository struct {
	db *sql.DB
}

// NewPaymentMethodRepository creates a new payment method repository
func NewPaymentMethodRepository(db *sql.DB) *PaymentMethodRepository {
	return &PaymentMethodRepository{db: db}
}

// Create creates a new payment method
func (r *PaymentMethodRepository) Create(paymentMethod *models.PaymentMethod) error {
	query := `
		INSERT INTO payment_methods (id, user_id, type, last4, brand, exp_month, exp_year, 
			is_default, stripe_payment_method_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`

	_, err := r.db.Exec(query,
		paymentMethod.ID, paymentMethod.UserID, paymentMethod.Type, paymentMethod.Last4,
		paymentMethod.Brand, paymentMethod.ExpMonth, paymentMethod.ExpYear, paymentMethod.IsDefault,
		paymentMethod.StripePaymentMethodID, paymentMethod.CreatedAt, paymentMethod.UpdatedAt)

	if err != nil {
		logrus.WithError(err).WithField("payment_method_id", paymentMethod.ID).Error("Failed to create payment method")
		return fmt.Errorf("failed to create payment method: %w", err)
	}

	logrus.WithField("payment_method_id", paymentMethod.ID).Info("Payment method created successfully")
	return nil
}

// GetByID retrieves a payment method by ID
func (r *PaymentMethodRepository) GetByID(id string) (*models.PaymentMethod, error) {
	query := `
		SELECT pm.id, pm.user_id, pm.type, pm.last4, pm.brand, pm.exp_month, pm.exp_year,
			pm.is_default, pm.stripe_payment_method_id, pm.created_at, pm.updated_at,
			u.username as user_name,
			CASE 
				WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
					CASE 
						WHEN EXTRACT(YEAR FROM NOW()) > pm.exp_year OR 
							 (EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) > pm.exp_month) THEN TRUE
						ELSE FALSE
					END
				ELSE FALSE
			END as is_expired,
			CASE 
				WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
					CASE 
						WHEN EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) = pm.exp_month THEN TRUE
						ELSE FALSE
					END
				ELSE FALSE
			END as expires_soon
		FROM payment_methods pm
		LEFT JOIN users u ON pm.user_id = u.id
		WHERE pm.id = $1
	`

	paymentMethod := &models.PaymentMethod{}
	err := r.db.QueryRow(query, id).Scan(
		&paymentMethod.ID, &paymentMethod.UserID, &paymentMethod.Type, &paymentMethod.Last4,
		&paymentMethod.Brand, &paymentMethod.ExpMonth, &paymentMethod.ExpYear, &paymentMethod.IsDefault,
		&paymentMethod.StripePaymentMethodID, &paymentMethod.CreatedAt, &paymentMethod.UpdatedAt,
		&paymentMethod.UserName, &paymentMethod.Expired, &paymentMethod.ExpiringSoon)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("payment method not found")
		}
		logrus.WithError(err).WithField("payment_method_id", id).Error("Failed to get payment method")
		return nil, fmt.Errorf("failed to get payment method: %w", err)
	}

	return paymentMethod, nil
}

// GetByUserID retrieves payment methods for a specific user
func (r *PaymentMethodRepository) GetByUserID(userID string, query *models.PaymentMethodQuery) ([]models.PaymentMethod, int64, error) {
	query.SetDefaults()

	// Build WHERE clause
	whereClause := "WHERE pm.user_id = $1"
	args := []interface{}{userID}
	argIndex := 2

	if query.Type != "" {
		whereClause += fmt.Sprintf(" AND pm.type = $%d", argIndex)
		args = append(args, query.Type)
		argIndex++
	}

	if query.IsDefault != nil {
		whereClause += fmt.Sprintf(" AND pm.is_default = $%d", argIndex)
		args = append(args, *query.IsDefault)
		argIndex++
	}

	// Build ORDER BY clause
	orderBy := fmt.Sprintf("ORDER BY pm.%s %s", query.SortBy, strings.ToUpper(query.SortOrder))

	// Count total records
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM payment_methods pm
		%s
	`, whereClause)

	var total int64
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		logrus.WithError(err).Error("Failed to count payment methods")
		return nil, 0, fmt.Errorf("failed to count payment methods: %w", err)
	}

	// Build main query
	mainQuery := fmt.Sprintf(`
		SELECT pm.id, pm.user_id, pm.type, pm.last4, pm.brand, pm.exp_month, pm.exp_year,
			pm.is_default, pm.stripe_payment_method_id, pm.created_at, pm.updated_at,
			u.username as user_name,
			CASE 
				WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
					CASE 
						WHEN EXTRACT(YEAR FROM NOW()) > pm.exp_year OR 
							 (EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) > pm.exp_month) THEN TRUE
						ELSE FALSE
					END
				ELSE FALSE
			END as is_expired,
			CASE 
				WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
					CASE 
						WHEN EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) = pm.exp_month THEN TRUE
						ELSE FALSE
					END
				ELSE FALSE
			END as expires_soon
		FROM payment_methods pm
		LEFT JOIN users u ON pm.user_id = u.id
		%s
		%s
		LIMIT $%d OFFSET $%d
	`, whereClause, orderBy, argIndex, argIndex+1)

	args = append(args, query.Limit, (query.Page-1)*query.Limit)

	rows, err := r.db.Query(mainQuery, args...)
	if err != nil {
		logrus.WithError(err).Error("Failed to query payment methods")
		return nil, 0, fmt.Errorf("failed to query payment methods: %w", err)
	}
	defer rows.Close()

	var paymentMethods []models.PaymentMethod
	for rows.Next() {
		paymentMethod := models.PaymentMethod{}
		err := rows.Scan(
			&paymentMethod.ID, &paymentMethod.UserID, &paymentMethod.Type, &paymentMethod.Last4,
			&paymentMethod.Brand, &paymentMethod.ExpMonth, &paymentMethod.ExpYear, &paymentMethod.IsDefault,
			&paymentMethod.StripePaymentMethodID, &paymentMethod.CreatedAt, &paymentMethod.UpdatedAt,
			&paymentMethod.UserName, &paymentMethod.Expired, &paymentMethod.ExpiringSoon)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan payment method")
			return nil, 0, fmt.Errorf("failed to scan payment method: %w", err)
		}
		paymentMethods = append(paymentMethods, paymentMethod)
	}

	return paymentMethods, total, nil
}

// GetDefaultByUserID retrieves the default payment method for a user
func (r *PaymentMethodRepository) GetDefaultByUserID(userID string) (*models.PaymentMethod, error) {
	query := `
		SELECT pm.id, pm.user_id, pm.type, pm.last4, pm.brand, pm.exp_month, pm.exp_year,
			pm.is_default, pm.stripe_payment_method_id, pm.created_at, pm.updated_at,
			u.username as user_name,
			CASE 
				WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
					CASE 
						WHEN EXTRACT(YEAR FROM NOW()) > pm.exp_year OR 
							 (EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) > pm.exp_month) THEN TRUE
						ELSE FALSE
					END
				ELSE FALSE
			END as is_expired,
			CASE 
				WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
					CASE 
						WHEN EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) = pm.exp_month THEN TRUE
						ELSE FALSE
					END
				ELSE FALSE
			END as expires_soon
		FROM payment_methods pm
		LEFT JOIN users u ON pm.user_id = u.id
		WHERE pm.user_id = $1 AND pm.is_default = TRUE
		LIMIT 1
	`

	paymentMethod := &models.PaymentMethod{}
	err := r.db.QueryRow(query, userID).Scan(
		&paymentMethod.ID, &paymentMethod.UserID, &paymentMethod.Type, &paymentMethod.Last4,
		&paymentMethod.Brand, &paymentMethod.ExpMonth, &paymentMethod.ExpYear, &paymentMethod.IsDefault,
		&paymentMethod.StripePaymentMethodID, &paymentMethod.CreatedAt, &paymentMethod.UpdatedAt,
		&paymentMethod.UserName, &paymentMethod.Expired, &paymentMethod.ExpiringSoon)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("no default payment method found")
		}
		logrus.WithError(err).WithField("user_id", userID).Error("Failed to get default payment method")
		return nil, fmt.Errorf("failed to get default payment method: %w", err)
	}

	return paymentMethod, nil
}

// UpdateDefault updates the default payment method for a user
func (r *PaymentMethodRepository) UpdateDefault(userID string, paymentMethodID string) error {
	// Start transaction
	tx, err := r.db.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Unset all default payment methods for the user
	unsetQuery := `
		UPDATE payment_methods 
		SET is_default = FALSE, updated_at = $1
		WHERE user_id = $2
	`

	_, err = tx.Exec(unsetQuery, time.Now(), userID)
	if err != nil {
		logrus.WithError(err).WithField("user_id", userID).Error("Failed to unset default payment methods")
		return fmt.Errorf("failed to unset default payment methods: %w", err)
	}

	// Set the specified payment method as default
	setQuery := `
		UPDATE payment_methods 
		SET is_default = TRUE, updated_at = $1
		WHERE id = $2 AND user_id = $3
	`

	result, err := tx.Exec(setQuery, time.Now(), paymentMethodID, userID)
	if err != nil {
		logrus.WithError(err).WithFields(logrus.Fields{
			"user_id":           userID,
			"payment_method_id": paymentMethodID,
		}).Error("Failed to set default payment method")
		return fmt.Errorf("failed to set default payment method: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("payment method not found or not owned by user")
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"user_id":           userID,
		"payment_method_id": paymentMethodID,
	}).Info("Default payment method updated successfully")
	return nil
}

// GetByStripeID retrieves a payment method by Stripe payment method ID
func (r *PaymentMethodRepository) GetByStripeID(stripeID string) (*models.PaymentMethod, error) {
	query := `
		SELECT pm.id, pm.user_id, pm.type, pm.last4, pm.brand, pm.exp_month, pm.exp_year,
			pm.is_default, pm.stripe_payment_method_id, pm.created_at, pm.updated_at,
			u.username as user_name,
			CASE 
				WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
					CASE 
						WHEN EXTRACT(YEAR FROM NOW()) > pm.exp_year OR 
							 (EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) > pm.exp_month) THEN TRUE
						ELSE FALSE
					END
				ELSE FALSE
			END as is_expired,
			CASE 
				WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
					CASE 
						WHEN EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) = pm.exp_month THEN TRUE
						ELSE FALSE
					END
				ELSE FALSE
			END as expires_soon
		FROM payment_methods pm
		LEFT JOIN users u ON pm.user_id = u.id
		WHERE pm.stripe_payment_method_id = $1
	`

	paymentMethod := &models.PaymentMethod{}
	err := r.db.QueryRow(query, stripeID).Scan(
		&paymentMethod.ID, &paymentMethod.UserID, &paymentMethod.Type, &paymentMethod.Last4,
		&paymentMethod.Brand, &paymentMethod.ExpMonth, &paymentMethod.ExpYear, &paymentMethod.IsDefault,
		&paymentMethod.StripePaymentMethodID, &paymentMethod.CreatedAt, &paymentMethod.UpdatedAt,
		&paymentMethod.UserName, &paymentMethod.Expired, &paymentMethod.ExpiringSoon)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("payment method not found")
		}
		logrus.WithError(err).WithField("stripe_payment_method_id", stripeID).Error("Failed to get payment method by Stripe ID")
		return nil, fmt.Errorf("failed to get payment method by Stripe ID: %w", err)
	}

	return paymentMethod, nil
}

// Delete deletes a payment method
func (r *PaymentMethodRepository) Delete(id string) error {
	query := `
		DELETE FROM payment_methods 
		WHERE id = $1
	`

	result, err := r.db.Exec(query, id)
	if err != nil {
		logrus.WithError(err).WithField("payment_method_id", id).Error("Failed to delete payment method")
		return fmt.Errorf("failed to delete payment method: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("payment method not found")
	}

	logrus.WithField("payment_method_id", id).Info("Payment method deleted successfully")
	return nil
}

// GetExpiringSoon retrieves payment methods expiring within the specified days
func (r *PaymentMethodRepository) GetExpiringSoon(days int) ([]models.PaymentMethod, error) {
	query := `
		SELECT pm.id, pm.user_id, pm.type, pm.last4, pm.brand, pm.exp_month, pm.exp_year,
			pm.is_default, pm.stripe_payment_method_id, pm.created_at, pm.updated_at,
			u.username as user_name,
			CASE 
				WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
					CASE 
						WHEN EXTRACT(YEAR FROM NOW()) > pm.exp_year OR 
							 (EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) > pm.exp_month) THEN TRUE
						ELSE FALSE
					END
				ELSE FALSE
			END as is_expired,
			CASE 
				WHEN pm.type = 'card' AND pm.exp_month IS NOT NULL AND pm.exp_year IS NOT NULL THEN
					CASE 
						WHEN EXTRACT(YEAR FROM NOW()) = pm.exp_year AND EXTRACT(MONTH FROM NOW()) = pm.exp_month THEN TRUE
						ELSE FALSE
					END
				ELSE FALSE
			END as expires_soon
		FROM payment_methods pm
		LEFT JOIN users u ON pm.user_id = u.id
		WHERE pm.type = 'card' 
		AND pm.exp_month IS NOT NULL 
		AND pm.exp_year IS NOT NULL
		AND EXTRACT(YEAR FROM NOW()) = pm.exp_year 
		AND EXTRACT(MONTH FROM NOW()) <= pm.exp_month 
		AND EXTRACT(MONTH FROM NOW()) + %d >= pm.exp_month
		ORDER BY pm.exp_year, pm.exp_month
	`

	rows, err := r.db.Query(fmt.Sprintf(query, days))
	if err != nil {
		logrus.WithError(err).Error("Failed to query expiring payment methods")
		return nil, fmt.Errorf("failed to query expiring payment methods: %w", err)
	}
	defer rows.Close()

	var paymentMethods []models.PaymentMethod
	for rows.Next() {
		paymentMethod := models.PaymentMethod{}
		err := rows.Scan(
			&paymentMethod.ID, &paymentMethod.UserID, &paymentMethod.Type, &paymentMethod.Last4,
			&paymentMethod.Brand, &paymentMethod.ExpMonth, &paymentMethod.ExpYear, &paymentMethod.IsDefault,
			&paymentMethod.StripePaymentMethodID, &paymentMethod.CreatedAt, &paymentMethod.UpdatedAt,
			&paymentMethod.UserName, &paymentMethod.Expired, &paymentMethod.ExpiringSoon)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan expiring payment method")
			return nil, fmt.Errorf("failed to scan expiring payment method: %w", err)
		}
		paymentMethods = append(paymentMethods, paymentMethod)
	}

	return paymentMethods, nil
}
