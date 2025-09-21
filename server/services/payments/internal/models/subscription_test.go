package models

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestSubscription_Validate(t *testing.T) {
	now := time.Now()
	
	tests := []struct {
		name        string
		subscription Subscription
		wantErr     bool
	}{
		{
			name: "valid subscription",
			subscription: Subscription{
				ID:                 uuid.New().String(),
				UserID:             uuid.New().String(),
				PlanID:             "plan_123",
				Status:             SubscriptionStatusActive,
				CurrentPeriodStart: now,
				CurrentPeriodEnd:   now.AddDate(0, 1, 0),
			},
			wantErr: false,
		},
		{
			name: "invalid user ID - empty",
			subscription: Subscription{
				ID:                 uuid.New().String(),
				UserID:             "",
				PlanID:             "plan_123",
				Status:             SubscriptionStatusActive,
				CurrentPeriodStart: now,
				CurrentPeriodEnd:   now.AddDate(0, 1, 0),
			},
			wantErr: true,
		},
		{
			name: "invalid plan ID - empty",
			subscription: Subscription{
				ID:                 uuid.New().String(),
				UserID:             uuid.New().String(),
				PlanID:             "",
				Status:             SubscriptionStatusActive,
				CurrentPeriodStart: now,
				CurrentPeriodEnd:   now.AddDate(0, 1, 0),
			},
			wantErr: true,
		},
		{
			name: "invalid period start - zero",
			subscription: Subscription{
				ID:                 uuid.New().String(),
				UserID:             uuid.New().String(),
				PlanID:             "plan_123",
				Status:             SubscriptionStatusActive,
				CurrentPeriodStart: time.Time{},
				CurrentPeriodEnd:   now.AddDate(0, 1, 0),
			},
			wantErr: true,
		},
		{
			name: "invalid period end - zero",
			subscription: Subscription{
				ID:                 uuid.New().String(),
				UserID:             uuid.New().String(),
				PlanID:             "plan_123",
				Status:             SubscriptionStatusActive,
				CurrentPeriodStart: now,
				CurrentPeriodEnd:   time.Time{},
			},
			wantErr: true,
		},
		{
			name: "invalid period - end before start",
			subscription: Subscription{
				ID:                 uuid.New().String(),
				UserID:             uuid.New().String(),
				PlanID:             "plan_123",
				Status:             SubscriptionStatusActive,
				CurrentPeriodStart: now,
				CurrentPeriodEnd:   now.AddDate(0, -1, 0),
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.subscription.Validate()
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestSubscription_IsActive(t *testing.T) {
	tests := []struct {
		name         string
		subscription Subscription
		expected     bool
	}{
		{
			name: "active subscription",
			subscription: Subscription{
				Status: SubscriptionStatusActive,
			},
			expected: true,
		},
		{
			name: "cancelled subscription",
			subscription: Subscription{
				Status: SubscriptionStatusCancelled,
			},
			expected: false,
		},
		{
			name: "expired subscription",
			subscription: Subscription{
				Status: SubscriptionStatusExpired,
			},
			expected: false,
		},
		{
			name: "past due subscription",
			subscription: Subscription{
				Status: SubscriptionStatusPastDue,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.subscription.IsActive())
		})
	}
}

func TestSubscription_IsCancelled(t *testing.T) {
	tests := []struct {
		name         string
		subscription Subscription
		expected     bool
	}{
		{
			name: "cancelled subscription",
			subscription: Subscription{
				Status: SubscriptionStatusCancelled,
			},
			expected: true,
		},
		{
			name: "active subscription",
			subscription: Subscription{
				Status: SubscriptionStatusActive,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.subscription.IsCancelled())
		})
	}
}

func TestSubscription_IsExpired(t *testing.T) {
	now := time.Now()
	
	tests := []struct {
		name         string
		subscription Subscription
		expected     bool
	}{
		{
			name: "expired subscription by status",
			subscription: Subscription{
				Status: SubscriptionStatusExpired,
			},
			expected: true,
		},
		{
			name: "expired subscription by time",
			subscription: Subscription{
				Status:             SubscriptionStatusActive,
				CurrentPeriodEnd:   now.AddDate(0, -1, 0),
			},
			expected: true,
		},
		{
			name: "active subscription",
			subscription: Subscription{
				Status:             SubscriptionStatusActive,
				CurrentPeriodEnd:   now.AddDate(0, 1, 0),
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.subscription.IsExpired())
		})
	}
}

func TestSubscription_IsPastDue(t *testing.T) {
	tests := []struct {
		name         string
		subscription Subscription
		expected     bool
	}{
		{
			name: "past due subscription",
			subscription: Subscription{
				Status: SubscriptionStatusPastDue,
			},
			expected: true,
		},
		{
			name: "active subscription",
			subscription: Subscription{
				Status: SubscriptionStatusActive,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.subscription.IsPastDue())
		})
	}
}

func TestSubscription_CanBeCancelled(t *testing.T) {
	tests := []struct {
		name         string
		subscription Subscription
		expected     bool
	}{
		{
			name: "active subscription",
			subscription: Subscription{
				Status: SubscriptionStatusActive,
			},
			expected: true,
		},
		{
			name: "cancelled subscription",
			subscription: Subscription{
				Status: SubscriptionStatusCancelled,
			},
			expected: false,
		},
		{
			name: "expired subscription",
			subscription: Subscription{
				Status: SubscriptionStatusExpired,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.subscription.CanBeCancelled())
		})
	}
}

func TestSubscription_CanBeUpdated(t *testing.T) {
	tests := []struct {
		name         string
		subscription Subscription
		expected     bool
	}{
		{
			name: "active subscription",
			subscription: Subscription{
				Status: SubscriptionStatusActive,
			},
			expected: true,
		},
		{
			name: "cancelled subscription",
			subscription: Subscription{
				Status: SubscriptionStatusCancelled,
			},
			expected: false,
		},
		{
			name: "expired subscription",
			subscription: Subscription{
				Status: SubscriptionStatusExpired,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.subscription.CanBeUpdated())
		})
	}
}

func TestSubscription_IsInCurrentPeriod(t *testing.T) {
	now := time.Now()
	
	tests := []struct {
		name         string
		subscription Subscription
		expected     bool
	}{
		{
			name: "in current period",
			subscription: Subscription{
				CurrentPeriodStart: now.AddDate(0, -1, 0),
				CurrentPeriodEnd:   now.AddDate(0, 1, 0),
			},
			expected: true,
		},
		{
			name: "before current period",
			subscription: Subscription{
				CurrentPeriodStart: now.AddDate(0, 1, 0),
				CurrentPeriodEnd:   now.AddDate(0, 2, 0),
			},
			expected: false,
		},
		{
			name: "after current period",
			subscription: Subscription{
				CurrentPeriodStart: now.AddDate(0, -2, 0),
				CurrentPeriodEnd:   now.AddDate(0, -1, 0),
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.subscription.IsInCurrentPeriod())
		})
	}
}

func TestSubscription_DaysUntilRenewal(t *testing.T) {
	now := time.Now()
	
	tests := []struct {
		name         string
		subscription Subscription
		expected     int
	}{
		{
			name: "active subscription with 30 days until renewal",
			subscription: Subscription{
				Status:             SubscriptionStatusActive,
				CurrentPeriodEnd:   now.AddDate(0, 0, 30),
			},
			expected: 30,
		},
		{
			name: "cancelled subscription",
			subscription: Subscription{
				Status: SubscriptionStatusCancelled,
			},
			expected: 0,
		},
		{
			name: "expired subscription",
			subscription: Subscription{
				Status:             SubscriptionStatusExpired,
				CurrentPeriodEnd:   now.AddDate(0, -1, 0),
			},
			expected: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.subscription.DaysUntilRenewal())
		})
	}
}

func TestSubscription_GetPlanPriceInDollars(t *testing.T) {
	subscription := Subscription{PlanPrice: 1999}
	assert.Equal(t, 19.99, subscription.GetPlanPriceInDollars())
}

func TestSubscription_GenerateID(t *testing.T) {
	subscription := &Subscription{}
	subscription.GenerateID()
	assert.NotEmpty(t, subscription.ID)
	assert.Regexp(t, `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`, subscription.ID)
}

func TestSubscription_SetTimestamps(t *testing.T) {
	subscription := &Subscription{}
	subscription.SetTimestamps()
	
	assert.False(t, subscription.CreatedAt.IsZero())
	assert.False(t, subscription.UpdatedAt.IsZero())
	assert.True(t, subscription.CreatedAt.Equal(subscription.UpdatedAt))
}

func TestSubscription_SetStatus(t *testing.T) {
	subscription := &Subscription{}
	subscription.SetStatus(SubscriptionStatusActive)
	
	assert.Equal(t, SubscriptionStatusActive, subscription.Status)
	assert.False(t, subscription.UpdatedAt.IsZero())
}

func TestSubscription_Cancel(t *testing.T) {
	subscription := &Subscription{}
	subscription.Cancel()
	
	assert.Equal(t, SubscriptionStatusCancelled, subscription.Status)
	assert.False(t, subscription.UpdatedAt.IsZero())
}

func TestSubscription_SetCancelAtPeriodEnd(t *testing.T) {
	subscription := &Subscription{}
	subscription.SetCancelAtPeriodEnd(true)
	
	assert.True(t, subscription.CancelAtPeriodEnd)
	assert.False(t, subscription.UpdatedAt.IsZero())
}
