package models

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

// PaymentMethod represents a payment method in the system
type PaymentMethod struct {
	ID                    string            `json:"id" db:"id"`
	UserID                string            `json:"userId" db:"user_id"`
	Type                  PaymentMethodType `json:"type" db:"type"`
	Last4                 string            `json:"last4" db:"last4"`
	Brand                 *string           `json:"brand,omitempty" db:"brand"`
	ExpMonth              *int              `json:"expMonth,omitempty" db:"exp_month"`
	ExpYear               *int              `json:"expYear,omitempty" db:"exp_year"`
	IsDefault             bool              `json:"isDefault" db:"is_default"`
	StripePaymentMethodID string            `json:"stripePaymentMethodId" db:"stripe_payment_method_id"`
	CreatedAt             time.Time         `json:"createdAt" db:"created_at"`
	UpdatedAt             time.Time         `json:"updatedAt" db:"updated_at"`
	// Computed fields
	UserName     string `json:"userName,omitempty" db:"user_name"`
	Expired      bool   `json:"expired,omitempty" db:"expired"`
	ExpiringSoon bool   `json:"expiringSoon,omitempty" db:"expiring_soon"`
}

// PaymentMethodType represents the type of payment method
type PaymentMethodType string

const (
	PaymentMethodTypeCard        PaymentMethodType = "card"
	PaymentMethodTypeBankAccount PaymentMethodType = "bank_account"
	PaymentMethodTypePayPal      PaymentMethodType = "paypal"
)

// PaymentMethodCreateRequest represents the request for creating a payment method
type PaymentMethodCreateRequest struct {
	Type                  PaymentMethodType `json:"type" binding:"required"`
	StripePaymentMethodID string            `json:"stripePaymentMethodId" binding:"required"`
	IsDefault             bool              `json:"isDefault"`
}

// PaymentMethodUpdateRequest represents the request for updating a payment method
type PaymentMethodUpdateRequest struct {
	IsDefault bool `json:"isDefault"`
}

// PaymentMethodListResponse represents the response for listing payment methods
type PaymentMethodListResponse struct {
	PaymentMethods []PaymentMethod `json:"paymentMethods"`
	Total          int64           `json:"total"`
	Page           int             `json:"page"`
	Limit          int             `json:"limit"`
	HasMore        bool            `json:"hasMore"`
}

// PaymentMethodQuery represents query parameters for listing payment methods
type PaymentMethodQuery struct {
	Page      int    `form:"page" binding:"min=1"`
	Limit     int    `form:"limit" binding:"min=1,max=100"`
	UserID    string `form:"userId"`
	Type      string `form:"type"`
	IsDefault *bool  `form:"isDefault"`
	SortBy    string `form:"sortBy"`
	SortOrder string `form:"sortOrder"`
}

// SetDefaults sets default values for the query
func (q *PaymentMethodQuery) SetDefaults() {
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

// Validate validates the payment method data
func (pm *PaymentMethod) Validate() error {
	if pm.UserID == "" {
		return fmt.Errorf("user ID is required")
	}
	if pm.Type == "" {
		return fmt.Errorf("payment method type is required")
	}
	if pm.StripePaymentMethodID == "" {
		return fmt.Errorf("Stripe payment method ID is required")
	}
	if pm.Type == PaymentMethodTypeCard {
		if pm.Last4 == "" {
			return fmt.Errorf("last 4 digits are required for card payment methods")
		}
		if pm.ExpMonth == nil || pm.ExpYear == nil {
			return fmt.Errorf("expiration month and year are required for card payment methods")
		}
		if *pm.ExpMonth < 1 || *pm.ExpMonth > 12 {
			return fmt.Errorf("expiration month must be between 1 and 12")
		}
		if *pm.ExpYear < time.Now().Year() {
			return fmt.Errorf("expiration year cannot be in the past")
		}
	}
	return nil
}

// IsCard checks if the payment method is a card
func (pm *PaymentMethod) IsCard() bool {
	return pm.Type == PaymentMethodTypeCard
}

// IsBankAccount checks if the payment method is a bank account
func (pm *PaymentMethod) IsBankAccount() bool {
	return pm.Type == PaymentMethodTypeBankAccount
}

// IsPayPal checks if the payment method is PayPal
func (pm *PaymentMethod) IsPayPal() bool {
	return pm.Type == PaymentMethodTypePayPal
}

// IsExpired checks if the payment method is expired (for cards)
func (pm *PaymentMethod) IsExpired() bool {
	if !pm.IsCard() || pm.ExpMonth == nil || pm.ExpYear == nil {
		return false
	}
	now := time.Now()
	return now.Year() > *pm.ExpYear || (now.Year() == *pm.ExpYear && int(now.Month()) > *pm.ExpMonth)
}

// ExpiresSoon checks if the payment method expires within 30 days (for cards)
func (pm *PaymentMethod) ExpiresSoon() bool {
	if !pm.IsCard() || pm.ExpMonth == nil || pm.ExpYear == nil {
		return false
	}
	now := time.Now()
	expiryDate := time.Date(*pm.ExpYear, time.Month(*pm.ExpMonth), 1, 0, 0, 0, 0, time.UTC)
	thirtyDaysFromNow := now.AddDate(0, 0, 30)
	return expiryDate.Before(thirtyDaysFromNow) && !pm.IsExpired()
}

// GenerateID generates a new UUID for the payment method
func (pm *PaymentMethod) GenerateID() {
	pm.ID = uuid.New().String()
}

// SetTimestamps sets the created and updated timestamps
func (pm *PaymentMethod) SetTimestamps() {
	now := time.Now()
	if pm.CreatedAt.IsZero() {
		pm.CreatedAt = now
	}
	pm.UpdatedAt = now
}

// SetDefault sets the payment method as default
func (pm *PaymentMethod) SetDefault() {
	pm.IsDefault = true
	pm.UpdatedAt = time.Now()
}

// UnsetDefault unsets the payment method as default
func (pm *PaymentMethod) UnsetDefault() {
	pm.IsDefault = false
	pm.UpdatedAt = time.Now()
}

// GetMaskedNumber returns a masked version of the payment method number
func (pm *PaymentMethod) GetMaskedNumber() string {
	if pm.IsCard() && pm.Last4 != "" {
		return "**** **** **** " + pm.Last4
	}
	if pm.IsBankAccount() && pm.Last4 != "" {
		return "****" + pm.Last4
	}
	return "****"
}

// GetDisplayName returns a display name for the payment method
func (pm *PaymentMethod) GetDisplayName() string {
	if pm.IsCard() && pm.Brand != nil {
		return *pm.Brand + " " + pm.GetMaskedNumber()
	}
	if pm.IsBankAccount() {
		return "Bank Account " + pm.GetMaskedNumber()
	}
	if pm.IsPayPal() {
		return "PayPal"
	}
	return string(pm.Type) + " " + pm.GetMaskedNumber()
}

// GetExpirationDate returns the expiration date for cards
func (pm *PaymentMethod) GetExpirationDate() *time.Time {
	if !pm.IsCard() || pm.ExpMonth == nil || pm.ExpYear == nil {
		return nil
	}
	expiryDate := time.Date(*pm.ExpYear, time.Month(*pm.ExpMonth), 1, 0, 0, 0, 0, time.UTC)
	return &expiryDate
}
