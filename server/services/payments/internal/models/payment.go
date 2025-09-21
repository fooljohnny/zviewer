package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// Payment represents a payment in the system
type Payment struct {
	ID              string          `json:"id" db:"id"`
	UserID          string          `json:"userId" db:"user_id"`
	Amount          int64           `json:"amount" db:"amount"` // Amount in cents
	Currency        string          `json:"currency" db:"currency"`
	Status          PaymentStatus   `json:"status" db:"status"`
	PaymentMethodID *string         `json:"paymentMethodId,omitempty" db:"payment_method_id"`
	TransactionID   *string         `json:"transactionId,omitempty" db:"transaction_id"`
	Description     string          `json:"description" db:"description"`
	Metadata        json.RawMessage `json:"metadata,omitempty" db:"metadata"`
	CreatedAt       time.Time       `json:"createdAt" db:"created_at"`
	UpdatedAt       time.Time       `json:"updatedAt" db:"updated_at"`
	// Computed fields
	UserName        string  `json:"userName,omitempty" db:"user_name"`
	RefundedAmount  int64   `json:"refundedAmount,omitempty" db:"refunded_amount"`
	RefundReason    *string `json:"refundReason,omitempty" db:"refund_reason"`
}

// PaymentStatus represents the status of a payment
type PaymentStatus string

const (
	PaymentStatusPending   PaymentStatus = "pending"
	PaymentStatusCompleted PaymentStatus = "completed"
	PaymentStatusFailed    PaymentStatus = "failed"
	PaymentStatusRefunded  PaymentStatus = "refunded"
	PaymentStatusCancelled PaymentStatus = "cancelled"
)

// PaymentCreateRequest represents the request for creating a payment
type PaymentCreateRequest struct {
	Amount          int64           `json:"amount" binding:"required,min=1"`
	Currency        string          `json:"currency" binding:"required,len=3"`
	PaymentMethodID *string         `json:"paymentMethodId,omitempty"`
	Description     string          `json:"description" binding:"required,min=1,max=500"`
	Metadata        json.RawMessage `json:"metadata,omitempty"`
}

// PaymentRefundRequest represents the request for refunding a payment
type PaymentRefundRequest struct {
	Amount int64   `json:"amount" binding:"min=1"`
	Reason *string `json:"reason,omitempty" binding:"max=500"`
}

// PaymentListResponse represents the response for listing payments
type PaymentListResponse struct {
	Payments []Payment `json:"payments"`
	Total    int64     `json:"total"`
	Page     int       `json:"page"`
	Limit    int       `json:"limit"`
	HasMore  bool      `json:"hasMore"`
}

// PaymentQuery represents query parameters for listing payments
type PaymentQuery struct {
	Page      int    `form:"page" binding:"min=1"`
	Limit     int    `form:"limit" binding:"min=1,max=100"`
	UserID    string `form:"userId"`
	Status    string `form:"status"`
	Currency  string `form:"currency"`
	DateFrom  string `form:"dateFrom"`
	DateTo    string `form:"dateTo"`
	SortBy    string `form:"sortBy"`
	SortOrder string `form:"sortOrder"`
}

// SetDefaults sets default values for the query
func (q *PaymentQuery) SetDefaults() {
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

// PaymentStats represents payment statistics
type PaymentStats struct {
	TotalPayments     int64   `json:"totalPayments"`
	TotalAmount       int64   `json:"totalAmount"`
	CompletedPayments int64   `json:"completedPayments"`
	FailedPayments    int64   `json:"failedPayments"`
	RefundedPayments  int64   `json:"refundedPayments"`
	AverageAmount     float64 `json:"averageAmount"`
	PaymentsToday     int64   `json:"paymentsToday"`
	PaymentsThisWeek  int64   `json:"paymentsThisWeek"`
	PaymentsThisMonth int64   `json:"paymentsThisMonth"`
}

// Validate validates the payment data
func (p *Payment) Validate() error {
	if p.Amount <= 0 {
		return fmt.Errorf("payment amount must be greater than 0")
	}
	if p.Currency == "" {
		return fmt.Errorf("currency is required")
	}
	if len(p.Currency) != 3 {
		return fmt.Errorf("currency must be a 3-letter code")
	}
	if p.UserID == "" {
		return fmt.Errorf("user ID is required")
	}
	if p.Description == "" {
		return fmt.Errorf("description is required")
	}
	if len(p.Description) > 500 {
		return fmt.Errorf("description cannot exceed 500 characters")
	}
	return nil
}

// IsCompleted checks if the payment is completed
func (p *Payment) IsCompleted() bool {
	return p.Status == PaymentStatusCompleted
}

// IsRefundable checks if the payment can be refunded
func (p *Payment) IsRefundable() bool {
	return p.Status == PaymentStatusCompleted && p.RefundedAmount < p.Amount
}

// CanBeRefunded checks if a specific amount can be refunded
func (p *Payment) CanBeRefunded(amount int64) bool {
	if !p.IsRefundable() {
		return false
	}
	return amount > 0 && amount <= (p.Amount-p.RefundedAmount)
}

// GenerateID generates a new UUID for the payment
func (p *Payment) GenerateID() {
	p.ID = uuid.New().String()
}

// SetTimestamps sets the created and updated timestamps
func (p *Payment) SetTimestamps() {
	now := time.Now()
	if p.CreatedAt.IsZero() {
		p.CreatedAt = now
	}
	p.UpdatedAt = now
}

// SetStatus updates the payment status and timestamp
func (p *Payment) SetStatus(status PaymentStatus) {
	p.Status = status
	p.UpdatedAt = time.Now()
}

// AddRefund adds a refund to the payment
func (p *Payment) AddRefund(amount int64, reason string) {
	p.RefundedAmount += amount
	if p.RefundedAmount >= p.Amount {
		p.Status = PaymentStatusRefunded
	}
	if reason != "" {
		p.RefundReason = &reason
	}
	p.UpdatedAt = time.Now()
}

// GetAmountInDollars returns the amount in dollars
func (p *Payment) GetAmountInDollars() float64 {
	return float64(p.Amount) / 100.0
}

// GetRefundedAmountInDollars returns the refunded amount in dollars
func (p *Payment) GetRefundedAmountInDollars() float64 {
	return float64(p.RefundedAmount) / 100.0
}

// GetRemainingAmount returns the remaining amount that can be refunded
func (p *Payment) GetRemainingAmount() int64 {
	return p.Amount - p.RefundedAmount
}

// Value implements the driver.Valuer interface for JSON fields
func (m json.RawMessage) Value() (driver.Value, error) {
	if m == nil {
		return nil, nil
	}
	return string(m), nil
}

// Scan implements the sql.Scanner interface for JSON fields
func (m *json.RawMessage) Scan(value interface{}) error {
	if value == nil {
		*m = nil
		return nil
	}
	
	switch v := value.(type) {
	case []byte:
		*m = json.RawMessage(v)
		return nil
	case string:
		*m = json.RawMessage(v)
		return nil
	default:
		return fmt.Errorf("cannot scan %T into json.RawMessage", value)
	}
}
