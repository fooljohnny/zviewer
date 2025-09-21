package services

import (
	"context"
	"testing"

	"zviewer-payments-service/internal/config"
	"zviewer-payments-service/internal/models"
	"zviewer-payments-service/internal/repositories"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"github.com/stripe/stripe-go/v76"
)

// MockStripeService is a mock implementation of StripeService
type MockStripeService struct {
	mock.Mock
}

func (m *MockStripeService) CreatePaymentIntent(ctx context.Context, amount int64, currency string, customerID string, paymentMethodID string, description string) (*stripe.PaymentIntent, error) {
	args := m.Called(ctx, amount, currency, customerID, paymentMethodID, description)
	return args.Get(0).(*stripe.PaymentIntent), args.Error(1)
}

func (m *MockStripeService) CreateCustomer(ctx context.Context, email string, name string, userID string) (*stripe.Customer, error) {
	args := m.Called(ctx, email, name, userID)
	return args.Get(0).(*stripe.Customer), args.Error(1)
}

func (m *MockStripeService) CreateRefund(ctx context.Context, paymentIntentID string, amount int64, reason string) (*stripe.Refund, error) {
	args := m.Called(ctx, paymentIntentID, amount, reason)
	return args.Get(0).(*stripe.Refund), args.Error(1)
}

func TestPaymentService_CreatePayment(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	config := &config.Config{
		MinPaymentAmount:    50,
		MaxPaymentAmount:    100000,
		SupportedCurrencies: []string{"USD", "EUR"},
	}

	mockStripeService := new(MockStripeService)
	paymentRepo := NewPaymentRepository(db)
	paymentService := NewPaymentService(paymentRepo, mockStripeService, config)

	userID := "user123"
	req := &models.PaymentCreateRequest{
		Amount:      1000,
		Currency:    "USD",
		Description: "Test payment",
	}

	// Mock Stripe customer creation
	mockStripeService.On("CreateCustomer", mock.Anything, "user@example.com", "User", userID).
		Return(&stripe.Customer{ID: "cus_123"}, nil)

	// Mock Stripe payment intent creation
	mockStripeService.On("CreatePaymentIntent", mock.Anything, int64(1000), "USD", "cus_123", "", "Test payment").
		Return(&stripe.PaymentIntent{ID: "pi_123"}, nil)

	// Mock database insert
	mock.ExpectExec("INSERT INTO payments").
		WithArgs(sqlmock.AnyArg(), userID, int64(1000), "USD", models.PaymentStatusCompleted,
			sqlmock.AnyArg(), sqlmock.AnyArg(), "Test payment", sqlmock.AnyArg(),
			int64(0), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg()).
		WillReturnResult(sqlmock.NewResult(1, 1))

	payment, err := paymentService.CreatePayment(context.Background(), userID, req)
	assert.NoError(t, err)
	assert.NotNil(t, payment)
	assert.Equal(t, userID, payment.UserID)
	assert.Equal(t, int64(1000), payment.Amount)
	assert.Equal(t, "USD", payment.Currency)
	assert.Equal(t, models.PaymentStatusCompleted, payment.Status)

	mockStripeService.AssertExpectations(t)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestPaymentService_CreatePayment_InvalidAmount(t *testing.T) {
	config := &config.Config{
		MinPaymentAmount:    50,
		MaxPaymentAmount:    100000,
		SupportedCurrencies: []string{"USD", "EUR"},
	}

	paymentService := NewPaymentService(nil, nil, config)

	userID := "user123"
	req := &models.PaymentCreateRequest{
		Amount:      25, // Below minimum
		Currency:    "USD",
		Description: "Test payment",
	}

	payment, err := paymentService.CreatePayment(context.Background(), userID, req)
	assert.Error(t, err)
	assert.Nil(t, payment)
	assert.Contains(t, err.Error(), "payment amount must be at least")
}

func TestPaymentService_CreatePayment_InvalidCurrency(t *testing.T) {
	config := &config.Config{
		MinPaymentAmount:    50,
		MaxPaymentAmount:    100000,
		SupportedCurrencies: []string{"USD", "EUR"},
	}

	paymentService := NewPaymentService(nil, nil, config)

	userID := "user123"
	req := &models.PaymentCreateRequest{
		Amount:      1000,
		Currency:    "INVALID",
		Description: "Test payment",
	}

	payment, err := paymentService.CreatePayment(context.Background(), userID, req)
	assert.Error(t, err)
	assert.Nil(t, payment)
	assert.Contains(t, err.Error(), "unsupported currency")
}

func TestPaymentService_ProcessRefund(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	config := &config.Config{}
	mockStripeService := new(MockStripeService)
	paymentRepo := NewPaymentRepository(db)
	paymentService := NewPaymentService(paymentRepo, mockStripeService, config)

	paymentID := "pay_123"
	userID := "user123"

	// Mock payment retrieval
	payment := &models.Payment{
		ID:              paymentID,
		UserID:          userID,
		Amount:          1000,
		Status:          models.PaymentStatusCompleted,
		RefundedAmount:  0,
		TransactionID:   stringPtr("pi_123"),
	}

	// Mock database queries
	mock.ExpectQuery("SELECT p.id, p.user_id").
		WithArgs(paymentID).
		WillReturnRows(sqlmock.NewRows([]string{
			"id", "user_id", "amount", "currency", "status", "payment_method_id",
			"transaction_id", "description", "metadata", "refunded_amount", "refund_reason",
			"created_at", "updated_at", "user_name",
		}).AddRow(
			payment.ID, payment.UserID, payment.Amount, "USD", payment.Status,
			nil, payment.TransactionID, "Test payment", nil, payment.RefundedAmount,
			nil, nil, nil, "testuser",
		))

	// Mock Stripe refund creation
	mockStripeService.On("CreateRefund", mock.Anything, "pi_123", int64(500), "Test refund").
		Return(&stripe.Refund{ID: "re_123"}, nil)

	// Mock database refund update
	mock.ExpectExec("UPDATE payments").
		WithArgs(int64(500), "Test refund", sqlmock.AnyArg(), paymentID).
		WillReturnResult(sqlmock.NewResult(0, 1))

	// Mock updated payment retrieval
	mock.ExpectQuery("SELECT p.id, p.user_id").
		WithArgs(paymentID).
		WillReturnRows(sqlmock.NewRows([]string{
			"id", "user_id", "amount", "currency", "status", "payment_method_id",
			"transaction_id", "description", "metadata", "refunded_amount", "refund_reason",
			"created_at", "updated_at", "user_name",
		}).AddRow(
			payment.ID, payment.UserID, payment.Amount, "USD", payment.Status,
			nil, payment.TransactionID, "Test payment", nil, int64(500),
			"Test refund", nil, nil, "testuser",
		))

	req := &models.PaymentRefundRequest{
		Amount: 500,
		Reason: stringPtr("Test refund"),
	}

	updatedPayment, err := paymentService.ProcessRefund(context.Background(), paymentID, req)
	assert.NoError(t, err)
	assert.NotNil(t, updatedPayment)
	assert.Equal(t, int64(500), updatedPayment.RefundedAmount)

	mockStripeService.AssertExpectations(t)
	assert.NoError(t, mock.ExpectationsWereMet())
}

// Helper function to create string pointer
func stringPtr(s string) *string {
	return &s
}
