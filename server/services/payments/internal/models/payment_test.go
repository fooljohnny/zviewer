package models

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestPayment_Validate(t *testing.T) {
	tests := []struct {
		name    string
		payment Payment
		wantErr bool
	}{
		{
			name: "valid payment",
			payment: Payment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				Amount:      1000,
				Currency:    "USD",
				Status:      PaymentStatusPending,
				Description: "Test payment",
			},
			wantErr: false,
		},
		{
			name: "invalid amount - zero",
			payment: Payment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				Amount:      0,
				Currency:    "USD",
				Status:      PaymentStatusPending,
				Description: "Test payment",
			},
			wantErr: true,
		},
		{
			name: "invalid amount - negative",
			payment: Payment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				Amount:      -100,
				Currency:    "USD",
				Status:      PaymentStatusPending,
				Description: "Test payment",
			},
			wantErr: true,
		},
		{
			name: "invalid currency - empty",
			payment: Payment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				Amount:      1000,
				Currency:    "",
				Status:      PaymentStatusPending,
				Description: "Test payment",
			},
			wantErr: true,
		},
		{
			name: "invalid currency - wrong length",
			payment: Payment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				Amount:      1000,
				Currency:    "US",
				Status:      PaymentStatusPending,
				Description: "Test payment",
			},
			wantErr: true,
		},
		{
			name: "invalid user ID - empty",
			payment: Payment{
				ID:          uuid.New().String(),
				UserID:      "",
				Amount:      1000,
				Currency:    "USD",
				Status:      PaymentStatusPending,
				Description: "Test payment",
			},
			wantErr: true,
		},
		{
			name: "invalid description - empty",
			payment: Payment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				Amount:      1000,
				Currency:    "USD",
				Status:      PaymentStatusPending,
				Description: "",
			},
			wantErr: true,
		},
		{
			name: "invalid description - too long",
			payment: Payment{
				ID:          uuid.New().String(),
				UserID:      uuid.New().String(),
				Amount:      1000,
				Currency:    "USD",
				Status:      PaymentStatusPending,
				Description: string(make([]byte, 501)), // 501 characters
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.payment.Validate()
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestPayment_IsCompleted(t *testing.T) {
	tests := []struct {
		name     string
		payment  Payment
		expected bool
	}{
		{
			name: "completed payment",
			payment: Payment{
				Status: PaymentStatusCompleted,
			},
			expected: true,
		},
		{
			name: "pending payment",
			payment: Payment{
				Status: PaymentStatusPending,
			},
			expected: false,
		},
		{
			name: "failed payment",
			payment: Payment{
				Status: PaymentStatusFailed,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.payment.IsCompleted())
		})
	}
}

func TestPayment_IsRefundable(t *testing.T) {
	tests := []struct {
		name     string
		payment  Payment
		expected bool
	}{
		{
			name: "completed payment with no refunds",
			payment: Payment{
				Status:         PaymentStatusCompleted,
				Amount:         1000,
				RefundedAmount: 0,
			},
			expected: true,
		},
		{
			name: "completed payment with partial refunds",
			payment: Payment{
				Status:         PaymentStatusCompleted,
				Amount:         1000,
				RefundedAmount: 500,
			},
			expected: true,
		},
		{
			name: "completed payment with full refunds",
			payment: Payment{
				Status:         PaymentStatusCompleted,
				Amount:         1000,
				RefundedAmount: 1000,
			},
			expected: false,
		},
		{
			name: "pending payment",
			payment: Payment{
				Status:         PaymentStatusPending,
				Amount:         1000,
				RefundedAmount: 0,
			},
			expected: false,
		},
		{
			name: "refunded payment",
			payment: Payment{
				Status:         PaymentStatusRefunded,
				Amount:         1000,
				RefundedAmount: 1000,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.payment.IsRefundable())
		})
	}
}

func TestPayment_CanBeRefunded(t *testing.T) {
	tests := []struct {
		name     string
		payment  Payment
		amount   int64
		expected bool
	}{
		{
			name: "valid refund amount",
			payment: Payment{
				Status:         PaymentStatusCompleted,
				Amount:         1000,
				RefundedAmount: 0,
			},
			amount:   500,
			expected: true,
		},
		{
			name: "refund amount exceeds remaining",
			payment: Payment{
				Status:         PaymentStatusCompleted,
				Amount:         1000,
				RefundedAmount: 600,
			},
			amount:   500,
			expected: false,
		},
		{
			name: "zero refund amount",
			payment: Payment{
				Status:         PaymentStatusCompleted,
				Amount:         1000,
				RefundedAmount: 0,
			},
			amount:   0,
			expected: false,
		},
		{
			name: "negative refund amount",
			payment: Payment{
				Status:         PaymentStatusCompleted,
				Amount:         1000,
				RefundedAmount: 0,
			},
			amount:   -100,
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.payment.CanBeRefunded(tt.amount))
		})
	}
}

func TestPayment_GetAmountInDollars(t *testing.T) {
	payment := Payment{Amount: 1234}
	assert.Equal(t, 12.34, payment.GetAmountInDollars())
}

func TestPayment_GetRefundedAmountInDollars(t *testing.T) {
	payment := Payment{RefundedAmount: 567}
	assert.Equal(t, 5.67, payment.GetRefundedAmountInDollars())
}

func TestPayment_GetRemainingAmount(t *testing.T) {
	payment := Payment{Amount: 1000, RefundedAmount: 300}
	assert.Equal(t, int64(700), payment.GetRemainingAmount())
}

func TestPayment_GenerateID(t *testing.T) {
	payment := &Payment{}
	payment.GenerateID()
	assert.NotEmpty(t, payment.ID)
	assert.Regexp(t, `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`, payment.ID)
}

func TestPayment_SetTimestamps(t *testing.T) {
	payment := &Payment{}
	payment.SetTimestamps()
	
	assert.False(t, payment.CreatedAt.IsZero())
	assert.False(t, payment.UpdatedAt.IsZero())
	assert.True(t, payment.CreatedAt.Equal(payment.UpdatedAt))
}

func TestPayment_SetStatus(t *testing.T) {
	payment := &Payment{}
	payment.SetStatus(PaymentStatusCompleted)
	
	assert.Equal(t, PaymentStatusCompleted, payment.Status)
	assert.False(t, payment.UpdatedAt.IsZero())
}

func TestPayment_AddRefund(t *testing.T) {
	payment := &Payment{
		Amount:         1000,
		RefundedAmount: 0,
		Status:         PaymentStatusCompleted,
	}
	
	payment.AddRefund(300, "Test refund")
	
	assert.Equal(t, int64(300), payment.RefundedAmount)
	assert.Equal(t, "Test refund", *payment.RefundReason)
	assert.Equal(t, PaymentStatusCompleted, payment.Status) // Not fully refunded yet
	
	payment.AddRefund(700, "Final refund")
	
	assert.Equal(t, int64(1000), payment.RefundedAmount)
	assert.Equal(t, PaymentStatusRefunded, payment.Status) // Now fully refunded
}
