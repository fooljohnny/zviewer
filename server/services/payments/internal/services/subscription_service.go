package services

import (
	"context"
	"fmt"
	"time"

	"zviewer-payments-service/internal/config"
	"zviewer-payments-service/internal/models"
	"zviewer-payments-service/internal/repositories"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"github.com/stripe/stripe-go/v76"
)

// SubscriptionService handles subscription business logic
type SubscriptionService struct {
	subscriptionRepo *repositories.SubscriptionRepository
	stripeService    *StripeService
	config           *config.Config
}

// NewSubscriptionService creates a new subscription service
func NewSubscriptionService(subscriptionRepo *repositories.SubscriptionRepository, stripeService *StripeService, config *config.Config) *SubscriptionService {
	return &SubscriptionService{
		subscriptionRepo: subscriptionRepo,
		stripeService:    stripeService,
		config:           config,
	}
}

// CreateSubscription creates a new subscription
func (s *SubscriptionService) CreateSubscription(ctx context.Context, userID string, req *models.SubscriptionCreateRequest) (*models.Subscription, error) {
	// Create subscription in Stripe
	sub, err := s.stripeService.CreateSubscription(ctx, "", req.PlanID, req.PaymentMethodID)
	if err != nil {
		return nil, fmt.Errorf("failed to create subscription in Stripe: %w", err)
	}

	// Create subscription model
	subscription := &models.Subscription{
		UserID:               userID,
		PlanID:               req.PlanID,
		Status:               models.SubscriptionStatusActive,
		CancelAtPeriodEnd:    req.CancelAtPeriodEnd,
		StripeSubscriptionID: &sub.ID,
	}

	// Generate ID and set timestamps
	subscription.GenerateID()
	subscription.SetTimestamps()

	// Set period information from Stripe
	if sub.CurrentPeriodStart > 0 {
		subscription.CurrentPeriodStart = time.Unix(sub.CurrentPeriodStart, 0)
	}
	if sub.CurrentPeriodEnd > 0 {
		subscription.CurrentPeriodEnd = time.Unix(sub.CurrentPeriodEnd, 0)
	}

	// Validate subscription data
	if err := subscription.Validate(); err != nil {
		return nil, fmt.Errorf("subscription validation failed: %w", err)
	}

	// Save subscription to database
	if err := s.subscriptionRepo.Create(subscription); err != nil {
		return nil, fmt.Errorf("failed to save subscription: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"subscription_id": subscription.ID,
		"user_id":         userID,
		"plan_id":         req.PlanID,
	}).Info("Subscription created successfully")

	return subscription, nil
}

// GetSubscription retrieves a subscription by ID
func (s *SubscriptionService) GetSubscription(ctx context.Context, subscriptionID string) (*models.Subscription, error) {
	subscription, err := s.subscriptionRepo.GetByID(subscriptionID)
	if err != nil {
		return nil, fmt.Errorf("failed to get subscription: %w", err)
	}

	return subscription, nil
}

// ListSubscriptions retrieves subscriptions for a user with pagination and filtering
func (s *SubscriptionService) ListSubscriptions(ctx context.Context, userID string, query *models.SubscriptionQuery) (*models.SubscriptionListResponse, error) {
	subscriptions, total, err := s.subscriptionRepo.GetByUserID(userID, query)
	if err != nil {
		return nil, fmt.Errorf("failed to list subscriptions: %w", err)
	}

	hasMore := int64(query.Page*query.Limit) < total

	response := &models.SubscriptionListResponse{
		Subscriptions: subscriptions,
		Total:         total,
		Page:          query.Page,
		Limit:         query.Limit,
		HasMore:       hasMore,
	}

	return response, nil
}

// UpdateSubscription updates a subscription
func (s *SubscriptionService) UpdateSubscription(ctx context.Context, subscriptionID string, req *models.SubscriptionUpdateRequest) (*models.Subscription, error) {
	// Get the subscription
	subscription, err := s.subscriptionRepo.GetByID(subscriptionID)
	if err != nil {
		return nil, fmt.Errorf("failed to get subscription: %w", err)
	}

	// Check if subscription can be updated
	if !subscription.CanBeUpdated() {
		return nil, fmt.Errorf("subscription cannot be updated")
	}

	// Update cancel at period end in Stripe if subscription exists
	if subscription.StripeSubscriptionID != nil {
		_, err := s.stripeService.CancelSubscription(ctx, *subscription.StripeSubscriptionID, req.CancelAtPeriodEnd)
		if err != nil {
			return nil, fmt.Errorf("failed to update subscription in Stripe: %w", err)
		}
	}

	// Update subscription in database
	if err := s.subscriptionRepo.UpdateCancelAtPeriodEnd(subscriptionID, req.CancelAtPeriodEnd); err != nil {
		return nil, fmt.Errorf("failed to update subscription: %w", err)
	}

	// Get updated subscription
	updatedSubscription, err := s.subscriptionRepo.GetByID(subscriptionID)
	if err != nil {
		return nil, fmt.Errorf("failed to get updated subscription: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"subscription_id":        subscriptionID,
		"cancel_at_period_end":   req.CancelAtPeriodEnd,
	}).Info("Subscription updated successfully")

	return updatedSubscription, nil
}

// CancelSubscription cancels a subscription
func (s *SubscriptionService) CancelSubscription(ctx context.Context, subscriptionID string) error {
	// Get the subscription
	subscription, err := s.subscriptionRepo.GetByID(subscriptionID)
	if err != nil {
		return fmt.Errorf("failed to get subscription: %w", err)
	}

	// Check if subscription can be cancelled
	if !subscription.CanBeCancelled() {
		return fmt.Errorf("subscription cannot be cancelled")
	}

	// Cancel subscription in Stripe if subscription exists
	if subscription.StripeSubscriptionID != nil {
		_, err := s.stripeService.CancelSubscription(ctx, *subscription.StripeSubscriptionID, false)
		if err != nil {
			return fmt.Errorf("failed to cancel subscription in Stripe: %w", err)
		}
	}

	// Update subscription status in database
	if err := s.subscriptionRepo.UpdateStatus(subscriptionID, models.SubscriptionStatusCancelled); err != nil {
		return fmt.Errorf("failed to update subscription status: %w", err)
	}

	logrus.WithField("subscription_id", subscriptionID).Info("Subscription cancelled successfully")
	return nil
}

// UpdateSubscriptionStatus updates the subscription status
func (s *SubscriptionService) UpdateSubscriptionStatus(subscriptionID string, status string) error {
	subscriptionStatus := models.SubscriptionStatus(status)
	
	// Validate status
	switch subscriptionStatus {
	case models.SubscriptionStatusActive, models.SubscriptionStatusCancelled, 
		 models.SubscriptionStatusExpired, models.SubscriptionStatusPastDue:
		// Valid status
	default:
		return fmt.Errorf("invalid subscription status: %s", status)
	}

	if err := s.subscriptionRepo.UpdateStatus(subscriptionID, subscriptionStatus); err != nil {
		return fmt.Errorf("failed to update subscription status: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"subscription_id": subscriptionID,
		"status":          status,
	}).Info("Subscription status updated successfully")

	return nil
}

// GetSubscriptionStats retrieves subscription statistics
func (s *SubscriptionService) GetSubscriptionStats(ctx context.Context) (*models.SubscriptionStats, error) {
	stats, err := s.subscriptionRepo.GetStats()
	if err != nil {
		return nil, fmt.Errorf("failed to get subscription stats: %w", err)
	}

	return stats, nil
}

// DeleteSubscription deletes a subscription (soft delete)
func (s *SubscriptionService) DeleteSubscription(ctx context.Context, subscriptionID string) error {
	// Get the subscription first to check if it can be deleted
	subscription, err := s.subscriptionRepo.GetByID(subscriptionID)
	if err != nil {
		return fmt.Errorf("failed to get subscription: %w", err)
	}

	// Check if subscription can be deleted
	if subscription.IsActive() {
		return fmt.Errorf("cannot delete active subscription")
	}

	if err := s.subscriptionRepo.Delete(subscriptionID); err != nil {
		return fmt.Errorf("failed to delete subscription: %w", err)
	}

	logrus.WithField("subscription_id", subscriptionID).Info("Subscription deleted successfully")
	return nil
}

// CreateSubscriptionFromStripe creates a subscription from Stripe webhook data
func (s *SubscriptionService) CreateSubscriptionFromStripe(sub *stripe.Subscription) error {
	// Convert Stripe subscription to our model
	subscription := s.stripeService.ConvertStripeSubscriptionToSubscription(sub, "")

	// Save subscription to database
	if err := s.subscriptionRepo.Create(subscription); err != nil {
		return fmt.Errorf("failed to save subscription from Stripe: %w", err)
	}

	logrus.WithField("subscription_id", subscription.ID).Info("Subscription created from Stripe webhook")
	return nil
}

// UpdateSubscriptionFromStripe updates a subscription from Stripe webhook data
func (s *SubscriptionService) UpdateSubscriptionFromStripe(sub *stripe.Subscription) error {
	// Get existing subscription by Stripe ID
	existingSubscription, err := s.subscriptionRepo.GetByStripeID(sub.ID)
	if err != nil {
		return fmt.Errorf("failed to get existing subscription: %w", err)
	}

	// Convert Stripe subscription to our model
	subscription := s.stripeService.ConvertStripeSubscriptionToSubscription(sub, existingSubscription.UserID)

	// Update subscription in database
	if err := s.subscriptionRepo.UpdateStatus(existingSubscription.ID, subscription.Status); err != nil {
		return fmt.Errorf("failed to update subscription status: %w", err)
	}

	// Update period if needed
	if subscription.CurrentPeriodStart != existingSubscription.CurrentPeriodStart ||
		subscription.CurrentPeriodEnd != existingSubscription.CurrentPeriodEnd {
		if err := s.subscriptionRepo.UpdatePeriod(existingSubscription.ID, subscription.CurrentPeriodStart, subscription.CurrentPeriodEnd); err != nil {
			return fmt.Errorf("failed to update subscription period: %w", err)
		}
	}

	// Update cancel at period end if needed
	if subscription.CancelAtPeriodEnd != existingSubscription.CancelAtPeriodEnd {
		if err := s.subscriptionRepo.UpdateCancelAtPeriodEnd(existingSubscription.ID, subscription.CancelAtPeriodEnd); err != nil {
			return fmt.Errorf("failed to update cancel at period end: %w", err)
		}
	}

	logrus.WithField("subscription_id", existingSubscription.ID).Info("Subscription updated from Stripe webhook")
	return nil
}

// GetExpiringSubscriptions retrieves subscriptions expiring soon
func (s *SubscriptionService) GetExpiringSubscriptions(ctx context.Context, days int) ([]models.Subscription, error) {
	subscriptions, err := s.subscriptionRepo.GetExpiringSoon(days)
	if err != nil {
		return nil, fmt.Errorf("failed to get expiring subscriptions: %w", err)
	}

	return subscriptions, nil
}
