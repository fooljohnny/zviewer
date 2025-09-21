package models

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestPaymentMethod_Validate(t *testing.T) {
	tests := []struct {
		name          string
		paymentMethod PaymentMethod
		wantErr       bool
	}{
		{
			name: "valid card payment method",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 PaymentMethodTypeCard,
				Last4:                "4242",
				Brand:                stringPtr("visa"),
				ExpMonth:             intPtr(12),
				ExpYear:              intPtr(2025),
				StripePaymentMethodID: "pm_123",
			},
			wantErr: false,
		},
		{
			name: "valid bank account payment method",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 PaymentMethodTypeBankAccount,
				Last4:                "1234",
				StripePaymentMethodID: "pm_123",
			},
			wantErr: false,
		},
		{
			name: "valid PayPal payment method",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 PaymentMethodTypePayPal,
				StripePaymentMethodID: "pm_123",
			},
			wantErr: false,
		},
		{
			name: "invalid user ID - empty",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               "",
				Type:                 PaymentMethodTypeCard,
				Last4:                "4242",
				StripePaymentMethodID: "pm_123",
			},
			wantErr: true,
		},
		{
			name: "invalid type - empty",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 "",
				Last4:                "4242",
				StripePaymentMethodID: "pm_123",
			},
			wantErr: true,
		},
		{
			name: "invalid Stripe ID - empty",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 PaymentMethodTypeCard,
				Last4:                "4242",
				StripePaymentMethodID: "",
			},
			wantErr: true,
		},
		{
			name: "invalid card - missing last4",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 PaymentMethodTypeCard,
				Last4:                "",
				StripePaymentMethodID: "pm_123",
			},
			wantErr: true,
		},
		{
			name: "invalid card - missing exp month",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 PaymentMethodTypeCard,
				Last4:                "4242",
				ExpYear:              intPtr(2025),
				StripePaymentMethodID: "pm_123",
			},
			wantErr: true,
		},
		{
			name: "invalid card - missing exp year",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 PaymentMethodTypeCard,
				Last4:                "4242",
				ExpMonth:             intPtr(12),
				StripePaymentMethodID: "pm_123",
			},
			wantErr: true,
		},
		{
			name: "invalid card - invalid exp month",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 PaymentMethodTypeCard,
				Last4:                "4242",
				ExpMonth:             intPtr(13),
				ExpYear:              intPtr(2025),
				StripePaymentMethodID: "pm_123",
			},
			wantErr: true,
		},
		{
			name: "invalid card - invalid exp month (0)",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 PaymentMethodTypeCard,
				Last4:                "4242",
				ExpMonth:             intPtr(0),
				ExpYear:              intPtr(2025),
				StripePaymentMethodID: "pm_123",
			},
			wantErr: true,
		},
		{
			name: "invalid card - past exp year",
			paymentMethod: PaymentMethod{
				ID:                   uuid.New().String(),
				UserID:               uuid.New().String(),
				Type:                 PaymentMethodTypeCard,
				Last4:                "4242",
				ExpMonth:             intPtr(12),
				ExpYear:              intPtr(2020),
				StripePaymentMethodID: "pm_123",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.paymentMethod.Validate()
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestPaymentMethod_IsCard(t *testing.T) {
	tests := []struct {
		name          string
		paymentMethod PaymentMethod
		expected      bool
	}{
		{
			name: "card payment method",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeCard,
			},
			expected: true,
		},
		{
			name: "bank account payment method",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeBankAccount,
			},
			expected: false,
		},
		{
			name: "PayPal payment method",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypePayPal,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.paymentMethod.IsCard())
		})
	}
}

func TestPaymentMethod_IsBankAccount(t *testing.T) {
	tests := []struct {
		name          string
		paymentMethod PaymentMethod
		expected      bool
	}{
		{
			name: "bank account payment method",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeBankAccount,
			},
			expected: true,
		},
		{
			name: "card payment method",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeCard,
			},
			expected: false,
		},
		{
			name: "PayPal payment method",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypePayPal,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.paymentMethod.IsBankAccount())
		})
	}
}

func TestPaymentMethod_IsPayPal(t *testing.T) {
	tests := []struct {
		name          string
		paymentMethod PaymentMethod
		expected      bool
	}{
		{
			name: "PayPal payment method",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypePayPal,
			},
			expected: true,
		},
		{
			name: "card payment method",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeCard,
			},
			expected: false,
		},
		{
			name: "bank account payment method",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeBankAccount,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.paymentMethod.IsPayPal())
		})
	}
}

func TestPaymentMethod_IsExpired(t *testing.T) {
	now := time.Now()
	
	tests := []struct {
		name          string
		paymentMethod PaymentMethod
		expected      bool
	}{
		{
			name: "expired card",
			paymentMethod: PaymentMethod{
				Type:     PaymentMethodTypeCard,
				ExpMonth: intPtr(1),
				ExpYear:  intPtr(now.Year() - 1),
			},
			expected: true,
		},
		{
			name: "expired card - same year, past month",
			paymentMethod: PaymentMethod{
				Type:     PaymentMethodTypeCard,
				ExpMonth: intPtr(int(now.Month()) - 1),
				ExpYear:  intPtr(now.Year()),
			},
			expected: true,
		},
		{
			name: "valid card",
			paymentMethod: PaymentMethod{
				Type:     PaymentMethodTypeCard,
				ExpMonth: intPtr(int(now.Month()) + 1),
				ExpYear:  intPtr(now.Year()),
			},
			expected: false,
		},
		{
			name: "bank account - not applicable",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeBankAccount,
			},
			expected: false,
		},
		{
			name: "PayPal - not applicable",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypePayPal,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.paymentMethod.IsExpired())
		})
	}
}

func TestPaymentMethod_ExpiresSoon(t *testing.T) {
	now := time.Now()
	
	tests := []struct {
		name          string
		paymentMethod PaymentMethod
		expected      bool
	}{
		{
			name: "expires soon - current month",
			paymentMethod: PaymentMethod{
				Type:     PaymentMethodTypeCard,
				ExpMonth: intPtr(int(now.Month())),
				ExpYear:  intPtr(now.Year()),
			},
			expected: true,
		},
		{
			name: "expires soon - next month",
			paymentMethod: PaymentMethod{
				Type:     PaymentMethodTypeCard,
				ExpMonth: intPtr(int(now.Month()) + 1),
				ExpYear:  intPtr(now.Year()),
			},
			expected: true,
		},
		{
			name: "expires soon - in 30 days",
			paymentMethod: PaymentMethod{
				Type:     PaymentMethodTypeCard,
				ExpMonth: intPtr(int(now.Month()) + 1),
				ExpYear:  intPtr(now.Year()),
			},
			expected: true,
		},
		{
			name: "does not expire soon",
			paymentMethod: PaymentMethod{
				Type:     PaymentMethodTypeCard,
				ExpMonth: intPtr(int(now.Month()) + 2),
				ExpYear:  intPtr(now.Year()),
			},
			expected: false,
		},
		{
			name: "bank account - not applicable",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeBankAccount,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.paymentMethod.ExpiresSoon())
		})
	}
}

func TestPaymentMethod_GetMaskedNumber(t *testing.T) {
	tests := []struct {
		name          string
		paymentMethod PaymentMethod
		expected      string
	}{
		{
			name: "card with last4",
			paymentMethod: PaymentMethod{
				Type:  PaymentMethodTypeCard,
				Last4: "4242",
			},
			expected: "**** **** **** 4242",
		},
		{
			name: "bank account with last4",
			paymentMethod: PaymentMethod{
				Type:  PaymentMethodTypeBankAccount,
				Last4: "1234",
			},
			expected: "****1234",
		},
		{
			name: "PayPal",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypePayPal,
			},
			expected: "****",
		},
		{
			name: "card without last4",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeCard,
			},
			expected: "****",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.paymentMethod.GetMaskedNumber())
		})
	}
}

func TestPaymentMethod_GetDisplayName(t *testing.T) {
	tests := []struct {
		name          string
		paymentMethod PaymentMethod
		expected      string
	}{
		{
			name: "card with brand",
			paymentMethod: PaymentMethod{
				Type:  PaymentMethodTypeCard,
				Brand: stringPtr("visa"),
				Last4: "4242",
			},
			expected: "visa **** **** **** 4242",
		},
		{
			name: "bank account",
			paymentMethod: PaymentMethod{
				Type:  PaymentMethodTypeBankAccount,
				Last4: "1234",
			},
			expected: "Bank Account ****1234",
		},
		{
			name: "PayPal",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypePayPal,
			},
			expected: "PayPal",
		},
		{
			name: "card without brand",
			paymentMethod: PaymentMethod{
				Type:  PaymentMethodTypeCard,
				Last4: "4242",
			},
			expected: "card **** **** **** 4242",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.expected, tt.paymentMethod.GetDisplayName())
		})
	}
}

func TestPaymentMethod_GetExpirationDate(t *testing.T) {
	tests := []struct {
		name          string
		paymentMethod PaymentMethod
		expected      *time.Time
	}{
		{
			name: "card with expiration",
			paymentMethod: PaymentMethod{
				Type:     PaymentMethodTypeCard,
				ExpMonth: intPtr(12),
				ExpYear:  intPtr(2025),
			},
			expected: &time.Time{},
		},
		{
			name: "card without expiration",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeCard,
			},
			expected: nil,
		},
		{
			name: "bank account",
			paymentMethod: PaymentMethod{
				Type: PaymentMethodTypeBankAccount,
			},
			expected: nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := tt.paymentMethod.GetExpirationDate()
			if tt.expected == nil {
				assert.Nil(t, result)
			} else {
				assert.NotNil(t, result)
				if tt.paymentMethod.ExpMonth != nil && tt.paymentMethod.ExpYear != nil {
					assert.Equal(t, *tt.paymentMethod.ExpMonth, int(result.Month()))
					assert.Equal(t, *tt.paymentMethod.ExpYear, result.Year())
				}
			}
		})
	}
}

func TestPaymentMethod_GenerateID(t *testing.T) {
	paymentMethod := &PaymentMethod{}
	paymentMethod.GenerateID()
	assert.NotEmpty(t, paymentMethod.ID)
	assert.Regexp(t, `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`, paymentMethod.ID)
}

func TestPaymentMethod_SetTimestamps(t *testing.T) {
	paymentMethod := &PaymentMethod{}
	paymentMethod.SetTimestamps()
	
	assert.False(t, paymentMethod.CreatedAt.IsZero())
	assert.False(t, paymentMethod.UpdatedAt.IsZero())
	assert.True(t, paymentMethod.CreatedAt.Equal(paymentMethod.UpdatedAt))
}

func TestPaymentMethod_SetDefault(t *testing.T) {
	paymentMethod := &PaymentMethod{}
	paymentMethod.SetDefault()
	
	assert.True(t, paymentMethod.IsDefault)
	assert.False(t, paymentMethod.UpdatedAt.IsZero())
}

func TestPaymentMethod_UnsetDefault(t *testing.T) {
	paymentMethod := &PaymentMethod{IsDefault: true}
	paymentMethod.UnsetDefault()
	
	assert.False(t, paymentMethod.IsDefault)
	assert.False(t, paymentMethod.UpdatedAt.IsZero())
}

// Helper functions
func stringPtr(s string) *string {
	return &s
}

func intPtr(i int) *int {
	return &i
}
