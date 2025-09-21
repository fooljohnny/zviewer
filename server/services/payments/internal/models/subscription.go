package models

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

// Subscription represents a subscription in the system
type Subscription struct {
	ID                  string             `json:"id" db:"id"`
	UserID              string             `json:"userId" db:"user_id"`
	PlanID              string             `json:"planId" db:"plan_id"`
	Status              SubscriptionStatus `json:"status" db:"status"`
	CurrentPeriodStart  time.Time          `json:"currentPeriodStart" db:"current_period_start"`
	CurrentPeriodEnd    time.Time          `json:"currentPeriodEnd" db:"current_period_end"`
	CancelAtPeriodEnd   bool               `json:"cancelAtPeriodEnd" db:"cancel_at_period_end"`
	StripeSubscriptionID *string           `json:"stripeSubscriptionId,omitempty" db:"stripe_subscription_id"`
	CreatedAt           time.Time          `json:"createdAt" db:"created_at"`
	UpdatedAt           time.Time          `json:"updatedAt" db:"updated_at"`
	// Computed fields
	UserName            string  `json:"userName,omitempty" db:"user_name"`
	PlanName            string  `json:"planName,omitempty" db:"plan_name"`
	PlanPrice           int64   `json:"planPrice,omitempty" db:"plan_price"`
	PlanCurrency        string  `json:"planCurrency,omitempty" db:"plan_currency"`
	PlanInterval        string  `json:"planInterval,omitempty" db:"plan_interval"`
}

// SubscriptionStatus represents the status of a subscription
type SubscriptionStatus string

const (
	SubscriptionStatusActive   SubscriptionStatus = "active"
	SubscriptionStatusCancelled SubscriptionStatus = "cancelled"
	SubscriptionStatusExpired  SubscriptionStatus = "expired"
	SubscriptionStatusPastDue  SubscriptionStatus = "past_due"
)

// SubscriptionCreateRequest represents the request for creating a subscription
type SubscriptionCreateRequest struct {
	PlanID            string `json:"planId" binding:"required"`
	PaymentMethodID   string `json:"paymentMethodId" binding:"required"`
	CancelAtPeriodEnd bool  `json:"cancelAtPeriodEnd"`
}

// SubscriptionUpdateRequest represents the request for updating a subscription
type SubscriptionUpdateRequest struct {
	CancelAtPeriodEnd bool `json:"cancelAtPeriodEnd"`
}

// SubscriptionListResponse represents the response for listing subscriptions
type SubscriptionListResponse struct {
	Subscriptions []Subscription `json:"subscriptions"`
	Total         int64          `json:"total"`
	Page          int            `json:"page"`
	Limit         int            `json:"limit"`
	HasMore       bool           `json:"hasMore"`
}

// SubscriptionQuery represents query parameters for listing subscriptions
type SubscriptionQuery struct {
	Page      int    `form:"page" binding:"min=1"`
	Limit     int    `form:"limit" binding:"min=1,max=100"`
	UserID    string `form:"userId"`
	Status    string `form:"status"`
	PlanID    string `form:"planId"`
	SortBy    string `form:"sortBy"`
	SortOrder string `form:"sortOrder"`
}

// SetDefaults sets default values for the query
func (q *SubscriptionQuery) SetDefaults() {
	if q.Page <= 0 {
		q.Page = 1
	}
	if q.Limit <= 0 {
		q.Limit = 20
	}
	if q.SortBy == "" {
		q.SortBy = "created_at"
	}
	if q.SortOrder == "" {
		q.SortOrder = "desc"
	}
}

// SubscriptionStats represents subscription statistics
type SubscriptionStats struct {
	TotalSubscriptions     int64 `json:"totalSubscriptions"`
	ActiveSubscriptions    int64 `json:"activeSubscriptions"`
	CancelledSubscriptions int64 `json:"cancelledSubscriptions"`
	ExpiredSubscriptions   int64 `json:"expiredSubscriptions"`
	PastDueSubscriptions   int64 `json:"pastDueSubscriptions"`
	SubscriptionsToday     int64 `json:"subscriptionsToday"`
	SubscriptionsThisWeek  int64 `json:"subscriptionsThisWeek"`
	SubscriptionsThisMonth int64 `json:"subscriptionsThisMonth"`
}

// Validate validates the subscription data
func (s *Subscription) Validate() error {
	if s.UserID == "" {
		return fmt.Errorf("user ID is required")
	}
	if s.PlanID == "" {
		return fmt.Errorf("plan ID is required")
	}
	if s.CurrentPeriodStart.IsZero() {
		return fmt.Errorf("current period start is required")
	}
	if s.CurrentPeriodEnd.IsZero() {
		return fmt.Errorf("current period end is required")
	}
	if s.CurrentPeriodEnd.Before(s.CurrentPeriodStart) {
		return fmt.Errorf("current period end must be after start")
	}
	return nil
}

// IsActive checks if the subscription is active
func (s *Subscription) IsActive() bool {
	return s.Status == SubscriptionStatusActive
}

// IsCancelled checks if the subscription is cancelled
func (s *Subscription) IsCancelled() bool {
	return s.Status == SubscriptionStatusCancelled
}

// IsExpired checks if the subscription is expired
func (s *Subscription) IsExpired() bool {
	return s.Status == SubscriptionStatusExpired || time.Now().After(s.CurrentPeriodEnd)
}

// IsPastDue checks if the subscription is past due
func (s *Subscription) IsPastDue() bool {
	return s.Status == SubscriptionStatusPastDue
}

// CanBeCancelled checks if the subscription can be cancelled
func (s *Subscription) CanBeCancelled() bool {
	return s.IsActive() && !s.IsCancelled()
}

// CanBeUpdated checks if the subscription can be updated
func (s *Subscription) CanBeUpdated() bool {
	return s.IsActive() && !s.IsCancelled() && !s.IsExpired()
}

// GenerateID generates a new UUID for the subscription
func (s *Subscription) GenerateID() {
	s.ID = uuid.New().String()
}

// SetTimestamps sets the created and updated timestamps
func (s *Subscription) SetTimestamps() {
	now := time.Now()
	if s.CreatedAt.IsZero() {
		s.CreatedAt = now
	}
	s.UpdatedAt = now
}

// SetStatus updates the subscription status and timestamp
func (s *Subscription) SetStatus(status SubscriptionStatus) {
	s.Status = status
	s.UpdatedAt = time.Now()
}

// Cancel cancels the subscription
func (s *Subscription) Cancel() {
	s.Status = SubscriptionStatusCancelled
	s.UpdatedAt = time.Now()
}

// SetCancelAtPeriodEnd sets whether to cancel at period end
func (s *Subscription) SetCancelAtPeriodEnd(cancelAtPeriodEnd bool) {
	s.CancelAtPeriodEnd = cancelAtPeriodEnd
	s.UpdatedAt = time.Now()
}

// IsInCurrentPeriod checks if the current time is within the current billing period
func (s *Subscription) IsInCurrentPeriod() bool {
	now := time.Now()
	return now.After(s.CurrentPeriodStart) && now.Before(s.CurrentPeriodEnd)
}

// DaysUntilRenewal returns the number of days until the next renewal
func (s *Subscription) DaysUntilRenewal() int {
	if s.IsCancelled() || s.IsExpired() {
		return 0
	}
	now := time.Now()
	if now.After(s.CurrentPeriodEnd) {
		return 0
	}
	return int(s.CurrentPeriodEnd.Sub(now).Hours() / 24)
}

// GetPlanPriceInDollars returns the plan price in dollars
func (s *Subscription) GetPlanPriceInDollars() float64 {
	return float64(s.PlanPrice) / 100.0
}
