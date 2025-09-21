package repositories

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"zviewer-payments-service/internal/models"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

// PaymentRepository handles payment data operations
type PaymentRepository struct {
	db *sql.DB
}

// NewPaymentRepository creates a new payment repository
func NewPaymentRepository(db *sql.DB) *PaymentRepository {
	return &PaymentRepository{db: db}
}

// Create creates a new payment
func (r *PaymentRepository) Create(payment *models.Payment) error {
	query := `
		INSERT INTO payments (id, user_id, amount, currency, status, payment_method_id, 
			transaction_id, description, metadata, refunded_amount, refund_reason, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
	`

	_, err := r.db.Exec(query,
		payment.ID, payment.UserID, payment.Amount, payment.Currency, payment.Status,
		payment.PaymentMethodID, payment.TransactionID, payment.Description, payment.Metadata,
		payment.RefundedAmount, payment.RefundReason, payment.CreatedAt, payment.UpdatedAt)

	if err != nil {
		logrus.WithError(err).WithField("payment_id", payment.ID).Error("Failed to create payment")
		return fmt.Errorf("failed to create payment: %w", err)
	}

	logrus.WithField("payment_id", payment.ID).Info("Payment created successfully")
	return nil
}

// GetByID retrieves a payment by ID
func (r *PaymentRepository) GetByID(id string) (*models.Payment, error) {
	query := `
		SELECT p.id, p.user_id, p.amount, p.currency, p.status, p.payment_method_id,
			p.transaction_id, p.description, p.metadata, p.refunded_amount, p.refund_reason,
			p.created_at, p.updated_at, u.username as user_name
		FROM payments p
		LEFT JOIN users u ON p.user_id = u.id
		WHERE p.id = $1
	`

	payment := &models.Payment{}
	err := r.db.QueryRow(query, id).Scan(
		&payment.ID, &payment.UserID, &payment.Amount, &payment.Currency, &payment.Status,
		&payment.PaymentMethodID, &payment.TransactionID, &payment.Description, &payment.Metadata,
		&payment.RefundedAmount, &payment.RefundReason, &payment.CreatedAt, &payment.UpdatedAt,
		&payment.UserName)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("payment not found")
		}
		logrus.WithError(err).WithField("payment_id", id).Error("Failed to get payment")
		return nil, fmt.Errorf("failed to get payment: %w", err)
	}

	return payment, nil
}

// GetByUserID retrieves payments for a specific user
func (r *PaymentRepository) GetByUserID(userID string, query *models.PaymentQuery) ([]models.Payment, int64, error) {
	query.SetDefaults()

	// Build WHERE clause
	whereClause := "WHERE p.user_id = $1"
	args := []interface{}{userID}
	argIndex := 2

	if query.Status != "" {
		whereClause += fmt.Sprintf(" AND p.status = $%d", argIndex)
		args = append(args, query.Status)
		argIndex++
	}

	if query.Currency != "" {
		whereClause += fmt.Sprintf(" AND p.currency = $%d", argIndex)
		args = append(args, query.Currency)
		argIndex++
	}

	if query.DateFrom != "" {
		whereClause += fmt.Sprintf(" AND p.created_at >= $%d", argIndex)
		args = append(args, query.DateFrom)
		argIndex++
	}

	if query.DateTo != "" {
		whereClause += fmt.Sprintf(" AND p.created_at <= $%d", argIndex)
		args = append(args, query.DateTo)
		argIndex++
	}

	// Build ORDER BY clause
	orderBy := fmt.Sprintf("ORDER BY p.%s %s", query.SortBy, strings.ToUpper(query.SortOrder))

	// Count total records
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM payments p
		%s
	`, whereClause)

	var total int64
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		logrus.WithError(err).Error("Failed to count payments")
		return nil, 0, fmt.Errorf("failed to count payments: %w", err)
	}

	// Build main query
	mainQuery := fmt.Sprintf(`
		SELECT p.id, p.user_id, p.amount, p.currency, p.status, p.payment_method_id,
			p.transaction_id, p.description, p.metadata, p.refunded_amount, p.refund_reason,
			p.created_at, p.updated_at, u.username as user_name
		FROM payments p
		LEFT JOIN users u ON p.user_id = u.id
		%s
		%s
		LIMIT $%d OFFSET $%d
	`, whereClause, orderBy, argIndex, argIndex+1)

	args = append(args, query.Limit, (query.Page-1)*query.Limit)

	rows, err := r.db.Query(mainQuery, args...)
	if err != nil {
		logrus.WithError(err).Error("Failed to query payments")
		return nil, 0, fmt.Errorf("failed to query payments: %w", err)
	}
	defer rows.Close()

	var payments []models.Payment
	for rows.Next() {
		payment := models.Payment{}
		err := rows.Scan(
			&payment.ID, &payment.UserID, &payment.Amount, &payment.Currency, &payment.Status,
			&payment.PaymentMethodID, &payment.TransactionID, &payment.Description, &payment.Metadata,
			&payment.RefundedAmount, &payment.RefundReason, &payment.CreatedAt, &payment.UpdatedAt,
			&payment.UserName)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan payment")
			return nil, 0, fmt.Errorf("failed to scan payment: %w", err)
		}
		payments = append(payments, payment)
	}

	return payments, total, nil
}

// UpdateStatus updates the payment status
func (r *PaymentRepository) UpdateStatus(id string, status models.PaymentStatus) error {
	query := `
		UPDATE payments 
		SET status = $1, updated_at = $2
		WHERE id = $3
	`

	result, err := r.db.Exec(query, status, time.Now(), id)
	if err != nil {
		logrus.WithError(err).WithField("payment_id", id).Error("Failed to update payment status")
		return fmt.Errorf("failed to update payment status: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("payment not found")
	}

	logrus.WithFields(logrus.Fields{
		"payment_id": id,
		"status":     status,
	}).Info("Payment status updated successfully")
	return nil
}

// AddRefund adds a refund to the payment
func (r *PaymentRepository) AddRefund(id string, amount int64, reason string) error {
	query := `
		UPDATE payments 
		SET refunded_amount = refunded_amount + $1, 
			refund_reason = $2, 
			status = CASE 
				WHEN refunded_amount + $1 >= amount THEN 'refunded'
				ELSE status
			END,
			updated_at = $3
		WHERE id = $4
	`

	result, err := r.db.Exec(query, amount, reason, time.Now(), id)
	if err != nil {
		logrus.WithError(err).WithField("payment_id", id).Error("Failed to add refund")
		return fmt.Errorf("failed to add refund: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("payment not found")
	}

	logrus.WithFields(logrus.Fields{
		"payment_id": id,
		"amount":     amount,
		"reason":     reason,
	}).Info("Refund added successfully")
	return nil
}

// GetStats retrieves payment statistics
func (r *PaymentRepository) GetStats() (*models.PaymentStats, error) {
	query := `
		SELECT 
			COUNT(*) as total_payments,
			COALESCE(SUM(amount), 0) as total_amount,
			COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_payments,
			COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_payments,
			COUNT(CASE WHEN status = 'refunded' THEN 1 END) as refunded_payments,
			COALESCE(AVG(CASE WHEN status = 'completed' THEN amount END), 0) as average_amount,
			COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as payments_today,
			COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as payments_this_week,
			COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as payments_this_month
		FROM payments
	`

	stats := &models.PaymentStats{}
	err := r.db.QueryRow(query).Scan(
		&stats.TotalPayments, &stats.TotalAmount, &stats.CompletedPayments,
		&stats.FailedPayments, &stats.RefundedPayments, &stats.AverageAmount,
		&stats.PaymentsToday, &stats.PaymentsThisWeek, &stats.PaymentsThisMonth)

	if err != nil {
		logrus.WithError(err).Error("Failed to get payment stats")
		return nil, fmt.Errorf("failed to get payment stats: %w", err)
	}

	return stats, nil
}

// GetByTransactionID retrieves a payment by transaction ID
func (r *PaymentRepository) GetByTransactionID(transactionID string) (*models.Payment, error) {
	query := `
		SELECT p.id, p.user_id, p.amount, p.currency, p.status, p.payment_method_id,
			p.transaction_id, p.description, p.metadata, p.refunded_amount, p.refund_reason,
			p.created_at, p.updated_at, u.username as user_name
		FROM payments p
		LEFT JOIN users u ON p.user_id = u.id
		WHERE p.transaction_id = $1
	`

	payment := &models.Payment{}
	err := r.db.QueryRow(query, transactionID).Scan(
		&payment.ID, &payment.UserID, &payment.Amount, &payment.Currency, &payment.Status,
		&payment.PaymentMethodID, &payment.TransactionID, &payment.Description, &payment.Metadata,
		&payment.RefundedAmount, &payment.RefundReason, &payment.CreatedAt, &payment.UpdatedAt,
		&payment.UserName)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("payment not found")
		}
		logrus.WithError(err).WithField("transaction_id", transactionID).Error("Failed to get payment by transaction ID")
		return nil, fmt.Errorf("failed to get payment by transaction ID: %w", err)
	}

	return payment, nil
}

// Delete deletes a payment (soft delete by setting status to cancelled)
func (r *PaymentRepository) Delete(id string) error {
	query := `
		UPDATE payments 
		SET status = 'cancelled', updated_at = $1
		WHERE id = $2
	`

	result, err := r.db.Exec(query, time.Now(), id)
	if err != nil {
		logrus.WithError(err).WithField("payment_id", id).Error("Failed to delete payment")
		return fmt.Errorf("failed to delete payment: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("payment not found")
	}

	logrus.WithField("payment_id", id).Info("Payment deleted successfully")
	return nil
}
