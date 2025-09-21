package repositories

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"zviewer-payments-service/internal/models"

	"github.com/sirupsen/logrus"
)

// SubscriptionRepository handles subscription data operations
type SubscriptionRepository struct {
	db *sql.DB
}

// NewSubscriptionRepository creates a new subscription repository
func NewSubscriptionRepository(db *sql.DB) *SubscriptionRepository {
	return &SubscriptionRepository{db: db}
}

// Create creates a new subscription
func (r *SubscriptionRepository) Create(subscription *models.Subscription) error {
	query := `
		INSERT INTO subscriptions (id, user_id, plan_id, status, current_period_start, 
			current_period_end, cancel_at_period_end, stripe_subscription_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`

	_, err := r.db.Exec(query,
		subscription.ID, subscription.UserID, subscription.PlanID, subscription.Status,
		subscription.CurrentPeriodStart, subscription.CurrentPeriodEnd, subscription.CancelAtPeriodEnd,
		subscription.StripeSubscriptionID, subscription.CreatedAt, subscription.UpdatedAt)

	if err != nil {
		logrus.WithError(err).WithField("subscription_id", subscription.ID).Error("Failed to create subscription")
		return fmt.Errorf("failed to create subscription: %w", err)
	}

	logrus.WithField("subscription_id", subscription.ID).Info("Subscription created successfully")
	return nil
}

// GetByID retrieves a subscription by ID
func (r *SubscriptionRepository) GetByID(id string) (*models.Subscription, error) {
	query := `
		SELECT s.id, s.user_id, s.plan_id, s.status, s.current_period_start, s.current_period_end,
			s.cancel_at_period_end, s.stripe_subscription_id, s.created_at, s.updated_at,
			u.username as user_name
		FROM subscriptions s
		LEFT JOIN users u ON s.user_id = u.id
		WHERE s.id = $1
	`

	subscription := &models.Subscription{}
	err := r.db.QueryRow(query, id).Scan(
		&subscription.ID, &subscription.UserID, &subscription.PlanID, &subscription.Status,
		&subscription.CurrentPeriodStart, &subscription.CurrentPeriodEnd, &subscription.CancelAtPeriodEnd,
		&subscription.StripeSubscriptionID, &subscription.CreatedAt, &subscription.UpdatedAt,
		&subscription.UserName)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("subscription not found")
		}
		logrus.WithError(err).WithField("subscription_id", id).Error("Failed to get subscription")
		return nil, fmt.Errorf("failed to get subscription: %w", err)
	}

	return subscription, nil
}

// GetByUserID retrieves subscriptions for a specific user
func (r *SubscriptionRepository) GetByUserID(userID string, query *models.SubscriptionQuery) ([]models.Subscription, int64, error) {
	query.SetDefaults()

	// Build WHERE clause
	whereClause := "WHERE s.user_id = $1"
	args := []interface{}{userID}
	argIndex := 2

	if query.Status != "" {
		whereClause += fmt.Sprintf(" AND s.status = $%d", argIndex)
		args = append(args, query.Status)
		argIndex++
	}

	if query.PlanID != "" {
		whereClause += fmt.Sprintf(" AND s.plan_id = $%d", argIndex)
		args = append(args, query.PlanID)
		argIndex++
	}

	// Build ORDER BY clause
	orderBy := fmt.Sprintf("ORDER BY s.%s %s", query.SortBy, strings.ToUpper(query.SortOrder))

	// Count total records
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM subscriptions s
		%s
	`, whereClause)

	var total int64
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		logrus.WithError(err).Error("Failed to count subscriptions")
		return nil, 0, fmt.Errorf("failed to count subscriptions: %w", err)
	}

	// Build main query
	mainQuery := fmt.Sprintf(`
		SELECT s.id, s.user_id, s.plan_id, s.status, s.current_period_start, s.current_period_end,
			s.cancel_at_period_end, s.stripe_subscription_id, s.created_at, s.updated_at,
			u.username as user_name
		FROM subscriptions s
		LEFT JOIN users u ON s.user_id = u.id
		%s
		%s
		LIMIT $%d OFFSET $%d
	`, whereClause, orderBy, argIndex, argIndex+1)

	args = append(args, query.Limit, (query.Page-1)*query.Limit)

	rows, err := r.db.Query(mainQuery, args...)
	if err != nil {
		logrus.WithError(err).Error("Failed to query subscriptions")
		return nil, 0, fmt.Errorf("failed to query subscriptions: %w", err)
	}
	defer rows.Close()

	var subscriptions []models.Subscription
	for rows.Next() {
		subscription := models.Subscription{}
		err := rows.Scan(
			&subscription.ID, &subscription.UserID, &subscription.PlanID, &subscription.Status,
			&subscription.CurrentPeriodStart, &subscription.CurrentPeriodEnd, &subscription.CancelAtPeriodEnd,
			&subscription.StripeSubscriptionID, &subscription.CreatedAt, &subscription.UpdatedAt,
			&subscription.UserName)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan subscription")
			return nil, 0, fmt.Errorf("failed to scan subscription: %w", err)
		}
		subscriptions = append(subscriptions, subscription)
	}

	return subscriptions, total, nil
}

// UpdateStatus updates the subscription status
func (r *SubscriptionRepository) UpdateStatus(id string, status models.SubscriptionStatus) error {
	query := `
		UPDATE subscriptions 
		SET status = $1, updated_at = $2
		WHERE id = $3
	`

	result, err := r.db.Exec(query, status, time.Now(), id)
	if err != nil {
		logrus.WithError(err).WithField("subscription_id", id).Error("Failed to update subscription status")
		return fmt.Errorf("failed to update subscription status: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("subscription not found")
	}

	logrus.WithFields(logrus.Fields{
		"subscription_id": id,
		"status":          status,
	}).Info("Subscription status updated successfully")
	return nil
}

// UpdateCancelAtPeriodEnd updates the cancel at period end flag
func (r *SubscriptionRepository) UpdateCancelAtPeriodEnd(id string, cancelAtPeriodEnd bool) error {
	query := `
		UPDATE subscriptions 
		SET cancel_at_period_end = $1, updated_at = $2
		WHERE id = $3
	`

	result, err := r.db.Exec(query, cancelAtPeriodEnd, time.Now(), id)
	if err != nil {
		logrus.WithError(err).WithField("subscription_id", id).Error("Failed to update cancel at period end")
		return fmt.Errorf("failed to update cancel at period end: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("subscription not found")
	}

	logrus.WithFields(logrus.Fields{
		"subscription_id":        id,
		"cancel_at_period_end":   cancelAtPeriodEnd,
	}).Info("Cancel at period end updated successfully")
	return nil
}

// UpdatePeriod updates the subscription period
func (r *SubscriptionRepository) UpdatePeriod(id string, periodStart, periodEnd time.Time) error {
	query := `
		UPDATE subscriptions 
		SET current_period_start = $1, current_period_end = $2, updated_at = $3
		WHERE id = $4
	`

	result, err := r.db.Exec(query, periodStart, periodEnd, time.Now(), id)
	if err != nil {
		logrus.WithError(err).WithField("subscription_id", id).Error("Failed to update subscription period")
		return fmt.Errorf("failed to update subscription period: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("subscription not found")
	}

	logrus.WithFields(logrus.Fields{
		"subscription_id": id,
		"period_start":    periodStart,
		"period_end":      periodEnd,
	}).Info("Subscription period updated successfully")
	return nil
}

// GetByStripeID retrieves a subscription by Stripe subscription ID
func (r *SubscriptionRepository) GetByStripeID(stripeID string) (*models.Subscription, error) {
	query := `
		SELECT s.id, s.user_id, s.plan_id, s.status, s.current_period_start, s.current_period_end,
			s.cancel_at_period_end, s.stripe_subscription_id, s.created_at, s.updated_at,
			u.username as user_name
		FROM subscriptions s
		LEFT JOIN users u ON s.user_id = u.id
		WHERE s.stripe_subscription_id = $1
	`

	subscription := &models.Subscription{}
	err := r.db.QueryRow(query, stripeID).Scan(
		&subscription.ID, &subscription.UserID, &subscription.PlanID, &subscription.Status,
		&subscription.CurrentPeriodStart, &subscription.CurrentPeriodEnd, &subscription.CancelAtPeriodEnd,
		&subscription.StripeSubscriptionID, &subscription.CreatedAt, &subscription.UpdatedAt,
		&subscription.UserName)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("subscription not found")
		}
		logrus.WithError(err).WithField("stripe_subscription_id", stripeID).Error("Failed to get subscription by Stripe ID")
		return nil, fmt.Errorf("failed to get subscription by Stripe ID: %w", err)
	}

	return subscription, nil
}

// GetStats retrieves subscription statistics
func (r *SubscriptionRepository) GetStats() (*models.SubscriptionStats, error) {
	query := `
		SELECT 
			COUNT(*) as total_subscriptions,
			COUNT(CASE WHEN status = 'active' THEN 1 END) as active_subscriptions,
			COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_subscriptions,
			COUNT(CASE WHEN status = 'expired' THEN 1 END) as expired_subscriptions,
			COUNT(CASE WHEN status = 'past_due' THEN 1 END) as past_due_subscriptions,
			COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as subscriptions_today,
			COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as subscriptions_this_week,
			COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as subscriptions_this_month
		FROM subscriptions
	`

	stats := &models.SubscriptionStats{}
	err := r.db.QueryRow(query).Scan(
		&stats.TotalSubscriptions, &stats.ActiveSubscriptions, &stats.CancelledSubscriptions,
		&stats.ExpiredSubscriptions, &stats.PastDueSubscriptions, &stats.SubscriptionsToday,
		&stats.SubscriptionsThisWeek, &stats.SubscriptionsThisMonth)

	if err != nil {
		logrus.WithError(err).Error("Failed to get subscription stats")
		return nil, fmt.Errorf("failed to get subscription stats: %w", err)
	}

	return stats, nil
}

// GetExpiringSoon retrieves subscriptions expiring within the specified days
func (r *SubscriptionRepository) GetExpiringSoon(days int) ([]models.Subscription, error) {
	query := `
		SELECT s.id, s.user_id, s.plan_id, s.status, s.current_period_start, s.current_period_end,
			s.cancel_at_period_end, s.stripe_subscription_id, s.created_at, s.updated_at,
			u.username as user_name
		FROM subscriptions s
		LEFT JOIN users u ON s.user_id = u.id
		WHERE s.status = 'active' 
		AND s.current_period_end <= NOW() + INTERVAL '%d days'
		AND s.current_period_end > NOW()
		ORDER BY s.current_period_end ASC
	`

	rows, err := r.db.Query(fmt.Sprintf(query, days))
	if err != nil {
		logrus.WithError(err).Error("Failed to query expiring subscriptions")
		return nil, fmt.Errorf("failed to query expiring subscriptions: %w", err)
	}
	defer rows.Close()

	var subscriptions []models.Subscription
	for rows.Next() {
		subscription := models.Subscription{}
		err := rows.Scan(
			&subscription.ID, &subscription.UserID, &subscription.PlanID, &subscription.Status,
			&subscription.CurrentPeriodStart, &subscription.CurrentPeriodEnd, &subscription.CancelAtPeriodEnd,
			&subscription.StripeSubscriptionID, &subscription.CreatedAt, &subscription.UpdatedAt,
			&subscription.UserName)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan expiring subscription")
			return nil, fmt.Errorf("failed to scan expiring subscription: %w", err)
		}
		subscriptions = append(subscriptions, subscription)
	}

	return subscriptions, nil
}

// Delete deletes a subscription (soft delete by setting status to cancelled)
func (r *SubscriptionRepository) Delete(id string) error {
	query := `
		UPDATE subscriptions 
		SET status = 'cancelled', updated_at = $1
		WHERE id = $2
	`

	result, err := r.db.Exec(query, time.Now(), id)
	if err != nil {
		logrus.WithError(err).WithField("subscription_id", id).Error("Failed to delete subscription")
		return fmt.Errorf("failed to delete subscription: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("subscription not found")
	}

	logrus.WithField("subscription_id", id).Info("Subscription deleted successfully")
	return nil
}
