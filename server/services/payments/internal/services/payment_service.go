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
)

// PaymentService handles payment business logic
type PaymentService struct {
	paymentRepo   *repositories.PaymentRepository
	stripeService *StripeService
	config        *config.Config
}

// NewPaymentService creates a new payment service
func NewPaymentService(paymentRepo *repositories.PaymentRepository, stripeService *StripeService, config *config.Config) *PaymentService {
	return &PaymentService{
		paymentRepo:   paymentRepo,
		stripeService: stripeService,
		config:        config,
	}
}

// CreatePayment creates a new payment
func (s *PaymentService) CreatePayment(ctx context.Context, userID string, req *models.PaymentCreateRequest) (*models.Payment, error) {
	// Validate payment amount
	if req.Amount < s.config.MinPaymentAmount {
		return nil, fmt.Errorf("payment amount must be at least %d cents", s.config.MinPaymentAmount)
	}
	if req.Amount > s.config.MaxPaymentAmount {
		return nil, fmt.Errorf("payment amount cannot exceed %d cents", s.config.MaxPaymentAmount)
	}

	// Validate currency
	if !s.isValidCurrency(req.Currency) {
		return nil, fmt.Errorf("unsupported currency: %s", req.Currency)
	}

	// Create payment model
	payment := &models.Payment{
		UserID:      userID,
		Amount:      req.Amount,
		Currency:    req.Currency,
		Status:      models.PaymentStatusPending,
		Description: req.Description,
		Metadata:    req.Metadata,
	}

	// Generate ID and set timestamps
	payment.GenerateID()
	payment.SetTimestamps()

	// Set payment method ID if provided
	if req.PaymentMethodID != nil {
		payment.PaymentMethodID = req.PaymentMethodID
	}

	// Validate payment data
	if err := payment.Validate(); err != nil {
		return nil, fmt.Errorf("payment validation failed: %w", err)
	}

	// Create payment intent in Stripe if payment method is provided
	if req.PaymentMethodID != nil {
		// Get or create Stripe customer for the user
		customerID, err := s.getOrCreateStripeCustomer(ctx, userID)
		if err != nil {
			return nil, fmt.Errorf("failed to get or create Stripe customer: %w", err)
		}

		pi, err := s.stripeService.CreatePaymentIntent(ctx, req.Amount, req.Currency, customerID, *req.PaymentMethodID, req.Description)
		if err != nil {
			return nil, fmt.Errorf("failed to create payment intent: %w", err)
		}

		payment.TransactionID = &pi.ID
		payment.Status = models.PaymentStatusCompleted
	}

	// Save payment to database
	if err := s.paymentRepo.Create(payment); err != nil {
		return nil, fmt.Errorf("failed to save payment: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"payment_id": payment.ID,
		"user_id":    userID,
		"amount":     req.Amount,
		"currency":   req.Currency,
	}).Info("Payment created successfully")

	return payment, nil
}

// GetPayment retrieves a payment by ID
func (s *PaymentService) GetPayment(ctx context.Context, paymentID string) (*models.Payment, error) {
	payment, err := s.paymentRepo.GetByID(paymentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get payment: %w", err)
	}

	return payment, nil
}

// ListPayments retrieves payments for a user with pagination and filtering
func (s *PaymentService) ListPayments(ctx context.Context, userID string, query *models.PaymentQuery) (*models.PaymentListResponse, error) {
	payments, total, err := s.paymentRepo.GetByUserID(userID, query)
	if err != nil {
		return nil, fmt.Errorf("failed to list payments: %w", err)
	}

	hasMore := int64(query.Page*query.Limit) < total

	response := &models.PaymentListResponse{
		Payments: payments,
		Total:    total,
		Page:     query.Page,
		Limit:    query.Limit,
		HasMore:  hasMore,
	}

	return response, nil
}

// ProcessRefund processes a refund for a payment
func (s *PaymentService) ProcessRefund(ctx context.Context, paymentID string, req *models.PaymentRefundRequest) (*models.Payment, error) {
	// Get the payment
	payment, err := s.paymentRepo.GetByID(paymentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get payment: %w", err)
	}

	// Check if payment can be refunded
	if !payment.IsRefundable() {
		return nil, fmt.Errorf("payment cannot be refunded")
	}

	// Determine refund amount
	refundAmount := req.Amount
	if refundAmount == 0 {
		refundAmount = payment.GetRemainingAmount()
	}

	// Validate refund amount
	if !payment.CanBeRefunded(refundAmount) {
		return nil, fmt.Errorf("invalid refund amount")
	}

	// Process refund in Stripe if transaction ID exists
	if payment.TransactionID != nil {
		_, err := s.stripeService.CreateRefund(ctx, *payment.TransactionID, refundAmount, req.GetReason())
		if err != nil {
			return nil, fmt.Errorf("failed to process refund in Stripe: %w", err)
		}
	}

	// Add refund to database
	if err := s.paymentRepo.AddRefund(paymentID, refundAmount, req.GetReason()); err != nil {
		return nil, fmt.Errorf("failed to add refund: %w", err)
	}

	// Get updated payment
	updatedPayment, err := s.paymentRepo.GetByID(paymentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get updated payment: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"payment_id":     paymentID,
		"refund_amount":  refundAmount,
		"refund_reason":  req.GetReason(),
	}).Info("Refund processed successfully")

	return updatedPayment, nil
}

// UpdatePaymentStatus updates the payment status
func (s *PaymentService) UpdatePaymentStatus(paymentID string, status string) error {
	paymentStatus := models.PaymentStatus(status)
	
	// Validate status
	switch paymentStatus {
	case models.PaymentStatusPending, models.PaymentStatusCompleted, models.PaymentStatusFailed, 
		 models.PaymentStatusRefunded, models.PaymentStatusCancelled:
		// Valid status
	default:
		return fmt.Errorf("invalid payment status: %s", status)
	}

	if err := s.paymentRepo.UpdateStatus(paymentID, paymentStatus); err != nil {
		return fmt.Errorf("failed to update payment status: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"payment_id": paymentID,
		"status":     status,
	}).Info("Payment status updated successfully")

	return nil
}

// GetPaymentStats retrieves payment statistics
func (s *PaymentService) GetPaymentStats(ctx context.Context) (*models.PaymentStats, error) {
	stats, err := s.paymentRepo.GetStats()
	if err != nil {
		return nil, fmt.Errorf("failed to get payment stats: %w", err)
	}

	return stats, nil
}

// DeletePayment deletes a payment (soft delete)
func (s *PaymentService) DeletePayment(ctx context.Context, paymentID string) error {
	// Get the payment first to check if it can be deleted
	payment, err := s.paymentRepo.GetByID(paymentID)
	if err != nil {
		return fmt.Errorf("failed to get payment: %w", err)
	}

	// Check if payment can be deleted
	if payment.Status == models.PaymentStatusCompleted && payment.RefundedAmount == 0 {
		return fmt.Errorf("cannot delete completed payment without refunds")
	}

	if err := s.paymentRepo.Delete(paymentID); err != nil {
		return fmt.Errorf("failed to delete payment: %w", err)
	}

	logrus.WithField("payment_id", paymentID).Info("Payment deleted successfully")
	return nil
}

// GetPaymentByTransactionID retrieves a payment by transaction ID
func (s *PaymentService) GetPaymentByTransactionID(ctx context.Context, transactionID string) (*models.Payment, error) {
	payment, err := s.paymentRepo.GetByTransactionID(transactionID)
	if err != nil {
		return nil, fmt.Errorf("failed to get payment by transaction ID: %w", err)
	}

	return payment, nil
}

// DeletePaymentMethod deletes a payment method
func (s *PaymentService) DeletePaymentMethod(paymentMethodID string) error {
	if err := s.paymentRepo.Delete(paymentMethodID); err != nil {
		return fmt.Errorf("failed to delete payment method: %w", err)
	}

	logrus.WithField("payment_method_id", paymentMethodID).Info("Payment method deleted successfully")
	return nil
}

// getOrCreateStripeCustomer gets or creates a Stripe customer for the user
func (s *PaymentService) getOrCreateStripeCustomer(ctx context.Context, userID string) (string, error) {
	// In a real implementation, you would:
	// 1. Check if user already has a Stripe customer ID stored in the database
	// 2. If not, create a new Stripe customer
	// 3. Store the customer ID in the database for future use
	
	// For now, we'll create a new customer each time
	// In production, you should implement proper customer management
	customer, err := s.stripeService.CreateCustomer(ctx, "user@example.com", "User", userID)
	if err != nil {
		return "", fmt.Errorf("failed to create Stripe customer: %w", err)
	}
	
	return customer.ID, nil
}

// isValidCurrency checks if the currency is supported
func (s *PaymentService) isValidCurrency(currency string) bool {
	for _, supportedCurrency := range s.config.SupportedCurrencies {
		if currency == supportedCurrency {
			return true
		}
	}
	return false
}

// GetReason returns the refund reason or empty string
func (r *models.PaymentRefundRequest) GetReason() string {
	if r.Reason == nil {
		return ""
	}
	return *r.Reason
}
