package services

import (
	"context"
	"fmt"
	"time"

	"zviewer-payments-service/internal/config"
	"zviewer-payments-service/internal/models"

	"github.com/sirupsen/logrus"
	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/customer"
	"github.com/stripe/stripe-go/v76/paymentintent"
	"github.com/stripe/stripe-go/v76/paymentmethod"
	"github.com/stripe/stripe-go/v76/refund"
	"github.com/stripe/stripe-go/v76/sub"
	"github.com/stripe/stripe-go/v76/webhook"
)

// StripeService handles Stripe API interactions
type StripeService struct {
	config *config.Config
}

// NewStripeService creates a new Stripe service
func NewStripeService(config *config.Config) *StripeService {
	return &StripeService{
		config: config,
	}
}

// CreatePaymentIntent creates a payment intent in Stripe
func (s *StripeService) CreatePaymentIntent(ctx context.Context, amount int64, currency string, customerID string, paymentMethodID string, description string) (*stripe.PaymentIntent, error) {
	params := &stripe.PaymentIntentParams{
		Amount:   stripe.Int64(amount),
		Currency: stripe.String(currency),
		PaymentMethod: stripe.String(paymentMethodID),
		ConfirmationMethod: stripe.String(string(stripe.PaymentIntentConfirmationMethodAutomatic)),
		Confirm:  stripe.Bool(true),
		Description: stripe.String(description),
	}

	if customerID != "" {
		params.Customer = stripe.String(customerID)
	}

	pi, err := paymentintent.New(params)
	if err != nil {
		logrus.WithError(err).Error("Failed to create payment intent")
		return nil, fmt.Errorf("failed to create payment intent: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"payment_intent_id": pi.ID,
		"amount": amount,
		"currency": currency,
	}).Info("Payment intent created successfully")

	return pi, nil
}

// ConfirmPaymentIntent confirms a payment intent
func (s *StripeService) ConfirmPaymentIntent(ctx context.Context, paymentIntentID string) (*stripe.PaymentIntent, error) {
	pi, err := paymentintent.Confirm(paymentIntentID, nil)
	if err != nil {
		logrus.WithError(err).WithField("payment_intent_id", paymentIntentID).Error("Failed to confirm payment intent")
		return nil, fmt.Errorf("failed to confirm payment intent: %w", err)
	}

	logrus.WithField("payment_intent_id", paymentIntentID).Info("Payment intent confirmed successfully")
	return pi, nil
}

// GetPaymentIntent retrieves a payment intent from Stripe
func (s *StripeService) GetPaymentIntent(ctx context.Context, paymentIntentID string) (*stripe.PaymentIntent, error) {
	pi, err := paymentintent.Get(paymentIntentID, nil)
	if err != nil {
		logrus.WithError(err).WithField("payment_intent_id", paymentIntentID).Error("Failed to get payment intent")
		return nil, fmt.Errorf("failed to get payment intent: %w", err)
	}

	return pi, nil
}

// CreatePaymentMethod creates a payment method in Stripe
func (s *StripeService) CreatePaymentMethod(ctx context.Context, paymentMethodType string, cardDetails map[string]interface{}) (*stripe.PaymentMethod, error) {
	params := &stripe.PaymentMethodParams{
		Type: stripe.String(paymentMethodType),
	}

	if paymentMethodType == "card" {
		params.Card = &stripe.PaymentMethodCardParams{
			Number:   stripe.String(cardDetails["number"].(string)),
			ExpMonth: stripe.Int64(int64(cardDetails["exp_month"].(int))),
			ExpYear:  stripe.Int64(int64(cardDetails["exp_year"].(int))),
			CVC:      stripe.String(cardDetails["cvc"].(string)),
		}
	}

	pm, err := paymentmethod.New(params)
	if err != nil {
		logrus.WithError(err).Error("Failed to create payment method")
		return nil, fmt.Errorf("failed to create payment method: %w", err)
	}

	logrus.WithField("payment_method_id", pm.ID).Info("Payment method created successfully")
	return pm, nil
}

// AttachPaymentMethod attaches a payment method to a customer
func (s *StripeService) AttachPaymentMethod(ctx context.Context, paymentMethodID string, customerID string) error {
	params := &stripe.PaymentMethodAttachParams{
		Customer: stripe.String(customerID),
	}

	_, err := paymentmethod.Attach(paymentMethodID, params)
	if err != nil {
		logrus.WithError(err).WithFields(logrus.Fields{
			"payment_method_id": paymentMethodID,
			"customer_id": customerID,
		}).Error("Failed to attach payment method")
		return fmt.Errorf("failed to attach payment method: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"payment_method_id": paymentMethodID,
		"customer_id": customerID,
	}).Info("Payment method attached successfully")
	return nil
}

// DetachPaymentMethod detaches a payment method from a customer
func (s *StripeService) DetachPaymentMethod(ctx context.Context, paymentMethodID string) error {
	_, err := paymentmethod.Detach(paymentMethodID, nil)
	if err != nil {
		logrus.WithError(err).WithField("payment_method_id", paymentMethodID).Error("Failed to detach payment method")
		return fmt.Errorf("failed to detach payment method: %w", err)
	}

	logrus.WithField("payment_method_id", paymentMethodID).Info("Payment method detached successfully")
	return nil
}

// GetPaymentMethod retrieves a payment method from Stripe
func (s *StripeService) GetPaymentMethod(ctx context.Context, paymentMethodID string) (*stripe.PaymentMethod, error) {
	pm, err := paymentmethod.Get(paymentMethodID, nil)
	if err != nil {
		logrus.WithError(err).WithField("payment_method_id", paymentMethodID).Error("Failed to get payment method")
		return nil, fmt.Errorf("failed to get payment method: %w", err)
	}

	return pm, nil
}

// CreateCustomer creates a customer in Stripe
func (s *StripeService) CreateCustomer(ctx context.Context, email string, name string, userID string) (*stripe.Customer, error) {
	params := &stripe.CustomerParams{
		Email: stripe.String(email),
		Name:  stripe.String(name),
		Metadata: map[string]string{
			"user_id": userID,
		},
	}

	c, err := customer.New(params)
	if err != nil {
		logrus.WithError(err).WithField("user_id", userID).Error("Failed to create customer")
		return nil, fmt.Errorf("failed to create customer: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"customer_id": c.ID,
		"user_id": userID,
	}).Info("Customer created successfully")
	return c, nil
}

// GetCustomer retrieves a customer from Stripe
func (s *StripeService) GetCustomer(ctx context.Context, customerID string) (*stripe.Customer, error) {
	c, err := customer.Get(customerID, nil)
	if err != nil {
		logrus.WithError(err).WithField("customer_id", customerID).Error("Failed to get customer")
		return nil, fmt.Errorf("failed to get customer: %w", err)
	}

	return c, nil
}

// CreateRefund creates a refund in Stripe
func (s *StripeService) CreateRefund(ctx context.Context, paymentIntentID string, amount int64, reason string) (*stripe.Refund, error) {
	params := &stripe.RefundParams{
		PaymentIntent: stripe.String(paymentIntentID),
		Amount:        stripe.Int64(amount),
	}

	if reason != "" {
		params.Reason = stripe.String(reason)
	}

	r, err := refund.New(params)
	if err != nil {
		logrus.WithError(err).WithFields(logrus.Fields{
			"payment_intent_id": paymentIntentID,
			"amount": amount,
		}).Error("Failed to create refund")
		return nil, fmt.Errorf("failed to create refund: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"refund_id": r.ID,
		"payment_intent_id": paymentIntentID,
		"amount": amount,
	}).Info("Refund created successfully")
	return r, nil
}

// CreateSubscription creates a subscription in Stripe
func (s *StripeService) CreateSubscription(ctx context.Context, customerID string, priceID string, paymentMethodID string) (*stripe.Subscription, error) {
	params := &stripe.SubscriptionParams{
		Customer: stripe.String(customerID),
		Items: []*stripe.SubscriptionItemsParams{
			{
				Price: stripe.String(priceID),
			},
		},
		DefaultPaymentMethod: stripe.String(paymentMethodID),
		PaymentBehavior: stripe.String(string(stripe.SubscriptionPaymentBehaviorDefaultIncomplete)),
		PaymentSettings: &stripe.SubscriptionPaymentSettingsParams{
			SaveDefaultPaymentMethod: stripe.String("on_subscription"),
		},
	}

	sub, err := sub.New(params)
	if err != nil {
		logrus.WithError(err).WithFields(logrus.Fields{
			"customer_id": customerID,
			"price_id": priceID,
		}).Error("Failed to create subscription")
		return nil, fmt.Errorf("failed to create subscription: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"subscription_id": sub.ID,
		"customer_id": customerID,
		"price_id": priceID,
	}).Info("Subscription created successfully")
	return sub, nil
}

// GetSubscription retrieves a subscription from Stripe
func (s *StripeService) GetSubscription(ctx context.Context, subscriptionID string) (*stripe.Subscription, error) {
	sub, err := sub.Get(subscriptionID, nil)
	if err != nil {
		logrus.WithError(err).WithField("subscription_id", subscriptionID).Error("Failed to get subscription")
		return nil, fmt.Errorf("failed to get subscription: %w", err)
	}

	return sub, nil
}

// CancelSubscription cancels a subscription in Stripe
func (s *StripeService) CancelSubscription(ctx context.Context, subscriptionID string, cancelAtPeriodEnd bool) (*stripe.Subscription, error) {
	params := &stripe.SubscriptionParams{}
	
	if cancelAtPeriodEnd {
		params.CancelAtPeriodEnd = stripe.Bool(true)
	} else {
		params.CancelAtPeriodEnd = stripe.Bool(false)
		params.CanceledAt = stripe.Int64(time.Now().Unix())
	}

	sub, err := sub.Update(subscriptionID, params)
	if err != nil {
		logrus.WithError(err).WithField("subscription_id", subscriptionID).Error("Failed to cancel subscription")
		return nil, fmt.Errorf("failed to cancel subscription: %w", err)
	}

	logrus.WithFields(logrus.Fields{
		"subscription_id": subscriptionID,
		"cancel_at_period_end": cancelAtPeriodEnd,
	}).Info("Subscription cancelled successfully")
	return sub, nil
}

// VerifyWebhookSignature verifies the webhook signature
func (s *StripeService) VerifyWebhookSignature(payload []byte, signature string) (*stripe.Event, error) {
	event, err := webhook.ConstructEvent(payload, signature, s.config.StripeWebhookSecret)
	if err != nil {
		logrus.WithError(err).Error("Failed to verify webhook signature")
		return nil, fmt.Errorf("failed to verify webhook signature: %w", err)
	}

	logrus.WithField("event_id", event.ID).Info("Webhook signature verified successfully")
	return &event, nil
}

// ConvertStripePaymentIntentToPayment converts a Stripe PaymentIntent to our Payment model
func (s *StripeService) ConvertStripePaymentIntentToPayment(pi *stripe.PaymentIntent, userID string) *models.Payment {
	payment := &models.Payment{
		ID:            pi.ID,
		UserID:        userID,
		Amount:        pi.Amount,
		Currency:      string(pi.Currency),
		TransactionID: &pi.ID,
		Description:   pi.Description,
		CreatedAt:     time.Unix(pi.Created, 0),
		UpdatedAt:     time.Unix(pi.Created, 0),
	}

	// Set status based on Stripe status
	switch pi.Status {
	case stripe.PaymentIntentStatusRequiresPaymentMethod, stripe.PaymentIntentStatusRequiresConfirmation:
		payment.Status = models.PaymentStatusPending
	case stripe.PaymentIntentStatusSucceeded:
		payment.Status = models.PaymentStatusCompleted
	case stripe.PaymentIntentStatusCanceled:
		payment.Status = models.PaymentStatusCancelled
	default:
		payment.Status = models.PaymentStatusFailed
	}

	// Set payment method ID if available
	if pi.PaymentMethod != nil {
		payment.PaymentMethodID = &pi.PaymentMethod.ID
	}

	return payment
}

// ConvertStripePaymentMethodToPaymentMethod converts a Stripe PaymentMethod to our PaymentMethod model
func (s *StripeService) ConvertStripePaymentMethodToPaymentMethod(pm *stripe.PaymentMethod, userID string) *models.PaymentMethod {
	paymentMethod := &models.PaymentMethod{
		ID:                   pm.ID,
		UserID:               userID,
		Type:                 models.PaymentMethodType(pm.Type),
		StripePaymentMethodID: pm.ID,
		CreatedAt:            time.Unix(pm.Created, 0),
		UpdatedAt:            time.Unix(pm.Created, 0),
	}

	// Set card-specific fields
	if pm.Card != nil {
		paymentMethod.Last4 = pm.Card.Last4
		paymentMethod.Brand = &pm.Card.Brand
		paymentMethod.ExpMonth = &pm.Card.ExpMonth
		paymentMethod.ExpYear = &pm.Card.ExpYear
	}

	return paymentMethod
}

// ConvertStripeSubscriptionToSubscription converts a Stripe Subscription to our Subscription model
func (s *StripeService) ConvertStripeSubscriptionToSubscription(sub *stripe.Subscription, userID string) *models.Subscription {
	subscription := &models.Subscription{
		ID:                  sub.ID,
		UserID:              userID,
		StripeSubscriptionID: &sub.ID,
		CreatedAt:           time.Unix(sub.Created, 0),
		UpdatedAt:           time.Unix(sub.Created, 0),
	}

	// Set status based on Stripe status
	switch sub.Status {
	case stripe.SubscriptionStatusActive:
		subscription.Status = models.SubscriptionStatusActive
	case stripe.SubscriptionStatusCanceled:
		subscription.Status = models.SubscriptionStatusCancelled
	case stripe.SubscriptionStatusPastDue:
		subscription.Status = models.SubscriptionStatusPastDue
	default:
		subscription.Status = models.SubscriptionStatusExpired
	}

	// Set period information
	if sub.CurrentPeriodStart > 0 {
		subscription.CurrentPeriodStart = time.Unix(sub.CurrentPeriodStart, 0)
	}
	if sub.CurrentPeriodEnd > 0 {
		subscription.CurrentPeriodEnd = time.Unix(sub.CurrentPeriodEnd, 0)
	}

	// Set cancel at period end
	subscription.CancelAtPeriodEnd = sub.CancelAtPeriodEnd

	// Set plan ID from the first item
	if len(sub.Items.Data) > 0 && sub.Items.Data[0].Price != nil {
		subscription.PlanID = sub.Items.Data[0].Price.ID
	}

	return subscription
}
