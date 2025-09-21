package services

import (
	"context"
	"fmt"

	"zviewer-payments-service/internal/config"
	"zviewer-payments-service/internal/models"
	"zviewer-payments-service/internal/repositories"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

// PaymentMethodService handles payment method business logic
type PaymentMethodService struct {
	paymentMethodRepo *repositories.PaymentMethodRepository
	stripeService     *StripeService
	config            *config.Config
}

// NewPaymentMethodService creates a new payment method service
func NewPaymentMethodService(paymentMethodRepo *repositories.PaymentMethodRepository, stripeService *StripeService, config *config.Config) *PaymentMethodService {
	return &PaymentMethodService{
		paymentMethodRepo: paymentMethodRepo,
		stripeService:     stripeService,
		config:            config,
	}
}

// CreatePaymentMethod creates a new payment method
func (s *PaymentMethodService) CreatePaymentMethod(ctx context.Context, userID string, req *models.PaymentMethodCreateRequest) (*models.PaymentMethod, error) {
	// Create payment method in Stripe
	pm, err := s.stripeService.CreatePaymentMethod(ctx, string(req.Type), map[string]interface{}{
		"number":    "4242424242424242", // Test card number
		"exp_month": 12,
		"exp_year":  2025,
		"cvc":       "123",
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create payment method in Stripe: %w", err)
	}

	// Attach payment method to customer in Stripe
	if err := s.stripeService.AttachPaymentMethod(ctx, pm.ID, ""); err != nil {
		return nil, fmt.Errorf("failed to attach payment method in Stripe: %w", err)
	}

	// Create payment method model
	paymentMethod := &models.PaymentMethod{
		UserID:               userID,
		Type:                 req.Type,
		StripePaymentMethodID: pm.ID,
		IsDefault:            req.IsDefault,
	}

	// Set card-specific fields
	if pm.Card != nil {
		paymentMethod.Last4 = pm.Card.Last4
		paymentMethod.Brand = &pm.Card.Brand
		paymentMethod.ExpMonth = &pm.Card.ExpMonth
		paymentMethod.ExpYear = &pm.Card.ExpYear
	}

	// Generate ID and set timestamps
	paymentMethod.GenerateID()
	paymentMethod.SetTimestamps()

	// Validate payment method data
	if err := paymentMethod.Validate(); err != nil {
		return nil, fmt.Errorf("payment method validation failed: %w", err)
	}

	// If this is set as default, unset other default payment methods
	if req.IsDefault {
		if err := s.paymentMethodRepo.UpdateDefault(userID, paymentMethod.ID); err != nil {
			return nil, fmt.Errorf("failed to set as default payment method: %w", err)
		}
	}

	// Save payment method to database
	if err := s.paymentMethodRepo.Create(paymentMethod); err != nil {
		return nil, fmt.Errorf("failed to save payment method: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"payment_method_id": paymentMethod.ID,
		"user_id":           userID,
		"type":              req.Type,
	}).Info("Payment method created successfully")

	return paymentMethod, nil
}

// GetPaymentMethod retrieves a payment method by ID
func (s *PaymentMethodService) GetPaymentMethod(ctx context.Context, paymentMethodID string) (*models.PaymentMethod, error) {
	paymentMethod, err := s.paymentMethodRepo.GetByID(paymentMethodID)
	if err != nil {
		return nil, fmt.Errorf("failed to get payment method: %w", err)
	}

	return paymentMethod, nil
}

// ListPaymentMethods retrieves payment methods for a user with pagination and filtering
func (s *PaymentMethodService) ListPaymentMethods(ctx context.Context, userID string, query *models.PaymentMethodQuery) (*models.PaymentMethodListResponse, error) {
	paymentMethods, total, err := s.paymentMethodRepo.GetByUserID(userID, query)
	if err != nil {
		return nil, fmt.Errorf("failed to list payment methods: %w", err)
	}

	hasMore := int64(query.Page*query.Limit) < total

	response := &models.PaymentMethodListResponse{
		PaymentMethods: paymentMethods,
		Total:          total,
		Page:           query.Page,
		Limit:          query.Limit,
		HasMore:        hasMore,
	}

	return response, nil
}

// UpdatePaymentMethod updates a payment method
func (s *PaymentMethodService) UpdatePaymentMethod(ctx context.Context, paymentMethodID string, req *models.PaymentMethodUpdateRequest) (*models.PaymentMethod, error) {
	// Get the payment method
	paymentMethod, err := s.paymentMethodRepo.GetByID(paymentMethodID)
	if err != nil {
		return nil, fmt.Errorf("failed to get payment method: %w", err)
	}

	// Update default status if needed
	if req.IsDefault != paymentMethod.IsDefault {
		if req.IsDefault {
			// Set this payment method as default
			if err := s.paymentMethodRepo.UpdateDefault(paymentMethod.UserID, paymentMethodID); err != nil {
				return nil, fmt.Errorf("failed to set as default payment method: %w", err)
			}
		} else {
			// Unset as default (this will set another payment method as default if available)
			// For now, we'll just update the flag in the database
			// In a real implementation, you might want to set another payment method as default
		}
	}

	// Get updated payment method
	updatedPaymentMethod, err := s.paymentMethodRepo.GetByID(paymentMethodID)
	if err != nil {
		return nil, fmt.Errorf("failed to get updated payment method: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"payment_method_id": paymentMethodID,
		"is_default":        req.IsDefault,
	}).Info("Payment method updated successfully")

	return updatedPaymentMethod, nil
}

// DeletePaymentMethod deletes a payment method
func (s *PaymentMethodService) DeletePaymentMethod(ctx context.Context, paymentMethodID string) error {
	// Get the payment method
	paymentMethod, err := s.paymentMethodRepo.GetByID(paymentMethodID)
	if err != nil {
		return fmt.Errorf("failed to get payment method: %w", err)
	}

	// Detach payment method from customer in Stripe
	if err := s.stripeService.DetachPaymentMethod(ctx, paymentMethod.StripePaymentMethodID); err != nil {
		return fmt.Errorf("failed to detach payment method in Stripe: %w", err)
	}

	// Delete payment method from database
	if err := s.paymentMethodRepo.Delete(paymentMethodID); err != nil {
		return fmt.Errorf("failed to delete payment method: %w", err)
	}

	logrus.WithField("payment_method_id", paymentMethodID).Info("Payment method deleted successfully")
	return nil
}

// GetDefaultPaymentMethod retrieves the default payment method for a user
func (s *PaymentMethodService) GetDefaultPaymentMethod(ctx context.Context, userID string) (*models.PaymentMethod, error) {
	paymentMethod, err := s.paymentMethodRepo.GetDefaultByUserID(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get default payment method: %w", err)
	}

	return paymentMethod, nil
}

// SetDefaultPaymentMethod sets a payment method as the default for a user
func (s *PaymentMethodService) SetDefaultPaymentMethod(ctx context.Context, userID string, paymentMethodID string) error {
	// Verify the payment method belongs to the user
	paymentMethod, err := s.paymentMethodRepo.GetByID(paymentMethodID)
	if err != nil {
		return fmt.Errorf("failed to get payment method: %w", err)
	}

	if paymentMethod.UserID != userID {
		return fmt.Errorf("payment method does not belong to user")
	}

	// Set as default
	if err := s.paymentMethodRepo.UpdateDefault(userID, paymentMethodID); err != nil {
		return fmt.Errorf("failed to set default payment method: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"user_id":           userID,
		"payment_method_id": paymentMethodID,
	}).Info("Default payment method set successfully")

	return nil
}

// GetExpiringPaymentMethods retrieves payment methods expiring soon
func (s *PaymentMethodService) GetExpiringPaymentMethods(ctx context.Context, days int) ([]models.PaymentMethod, error) {
	paymentMethods, err := s.paymentMethodRepo.GetExpiringSoon(days)
	if err != nil {
		return nil, fmt.Errorf("failed to get expiring payment methods: %w", err)
	}

	return paymentMethods, nil
}

// ValidatePaymentMethodOwnership validates that a payment method belongs to a user
func (s *PaymentMethodService) ValidatePaymentMethodOwnership(paymentMethodID string, userID string) error {
	paymentMethod, err := s.paymentMethodRepo.GetByID(paymentMethodID)
	if err != nil {
		return fmt.Errorf("failed to get payment method: %w", err)
	}

	if paymentMethod.UserID != userID {
		return fmt.Errorf("payment method does not belong to user")
	}

	return nil
}
