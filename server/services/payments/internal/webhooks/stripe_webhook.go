package webhooks

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"zviewer-payments-service/internal/config"
	"zviewer-payments-service/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"github.com/stripe/stripe-go/v76"
)

// StripeWebhookHandler handles Stripe webhook events
type StripeWebhookHandler struct {
	stripeService        *services.StripeService
	paymentService       *services.PaymentService
	subscriptionService  *services.SubscriptionService
	config               *config.Config
}

// NewStripeWebhookHandler creates a new Stripe webhook handler
func NewStripeWebhookHandler(
	stripeService *services.StripeService,
	paymentService *services.PaymentService,
	subscriptionService *services.SubscriptionService,
	config *config.Config,
) *StripeWebhookHandler {
	return &StripeWebhookHandler{
		stripeService:       stripeService,
		paymentService:      paymentService,
		subscriptionService: subscriptionService,
		config:              config,
	}
}

// HandleWebhook handles incoming Stripe webhook events
func (h *StripeWebhookHandler) HandleWebhook(c *gin.Context) {
	// Read the request body
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		logrus.WithError(err).Error("Failed to read webhook body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to read request body"})
		return
	}

	// Get the signature from headers
	signature := c.GetHeader("Stripe-Signature")
	if signature == "" {
		logrus.WithFields(logrus.Fields{
			"remote_addr": c.ClientIP(),
			"user_agent":  c.Request.UserAgent(),
		}).Warn("Missing Stripe signature header - potential security issue")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing Stripe signature"})
		return
	}

	// Verify the webhook signature
	event, err := h.stripeService.VerifyWebhookSignature(body, signature)
	if err != nil {
		logrus.WithFields(logrus.Fields{
			"error":       err.Error(),
			"remote_addr": c.ClientIP(),
			"user_agent":  c.Request.UserAgent(),
			"body_size":   len(body),
		}).Error("Failed to verify webhook signature - potential security breach")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid webhook signature"})
		return
	}

	// Log successful signature verification
	logrus.WithFields(logrus.Fields{
		"event_id":    event.ID,
		"event_type":  event.Type,
		"remote_addr": c.ClientIP(),
	}).Info("Webhook signature verified successfully")

	// Process the event
	if err := h.processEvent(event); err != nil {
		logrus.WithError(err).WithFields(logrus.Fields{
			"event_id":   event.ID,
			"event_type": event.Type,
		}).Error("Failed to process webhook event")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process event"})
		return
	}

	logrus.WithFields(logrus.Fields{
		"event_id":   event.ID,
		"event_type": event.Type,
	}).Info("Webhook event processed successfully")

	c.JSON(http.StatusOK, gin.H{"status": "success"})
}

// processEvent processes a Stripe webhook event
func (h *StripeWebhookHandler) processEvent(event *stripe.Event) error {
	logrus.WithFields(logrus.Fields{
		"event_id":   event.ID,
		"event_type": event.Type,
	}).Info("Processing Stripe webhook event")

	switch event.Type {
	case "payment_intent.succeeded":
		return h.handlePaymentIntentSucceeded(event)
	case "payment_intent.payment_failed":
		return h.handlePaymentIntentFailed(event)
	case "payment_intent.canceled":
		return h.handlePaymentIntentCanceled(event)
	case "payment_method.attached":
		return h.handlePaymentMethodAttached(event)
	case "payment_method.detached":
		return h.handlePaymentMethodDetached(event)
	case "customer.subscription.created":
		return h.handleSubscriptionCreated(event)
	case "customer.subscription.updated":
		return h.handleSubscriptionUpdated(event)
	case "customer.subscription.deleted":
		return h.handleSubscriptionDeleted(event)
	case "invoice.payment_succeeded":
		return h.handleInvoicePaymentSucceeded(event)
	case "invoice.payment_failed":
		return h.handleInvoicePaymentFailed(event)
	default:
		logrus.WithField("event_type", event.Type).Info("Unhandled webhook event type")
		return nil
	}
}

// handlePaymentIntentSucceeded handles payment intent succeeded events
func (h *StripeWebhookHandler) handlePaymentIntentSucceeded(event *stripe.Event) error {
	var pi stripe.PaymentIntent
	if err := json.Unmarshal(event.Data.Raw, &pi); err != nil {
		return fmt.Errorf("failed to unmarshal payment intent: %w", err)
	}

	// Update payment status in database
	if err := h.paymentService.UpdatePaymentStatus(pi.ID, "completed"); err != nil {
		return fmt.Errorf("failed to update payment status: %w", err)
	}

	logrus.WithField("payment_intent_id", pi.ID).Info("Payment intent succeeded")
	return nil
}

// handlePaymentIntentFailed handles payment intent failed events
func (h *StripeWebhookHandler) handlePaymentIntentFailed(event *stripe.Event) error {
	var pi stripe.PaymentIntent
	if err := json.Unmarshal(event.Data.Raw, &pi); err != nil {
		return fmt.Errorf("failed to unmarshal payment intent: %w", err)
	}

	// Update payment status in database
	if err := h.paymentService.UpdatePaymentStatus(pi.ID, "failed"); err != nil {
		return fmt.Errorf("failed to update payment status: %w", err)
	}

	logrus.WithField("payment_intent_id", pi.ID).Info("Payment intent failed")
	return nil
}

// handlePaymentIntentCanceled handles payment intent canceled events
func (h *StripeWebhookHandler) handlePaymentIntentCanceled(event *stripe.Event) error {
	var pi stripe.PaymentIntent
	if err := json.Unmarshal(event.Data.Raw, &pi); err != nil {
		return fmt.Errorf("failed to unmarshal payment intent: %w", err)
	}

	// Update payment status in database
	if err := h.paymentService.UpdatePaymentStatus(pi.ID, "cancelled"); err != nil {
		return fmt.Errorf("failed to update payment status: %w", err)
	}

	logrus.WithField("payment_intent_id", pi.ID).Info("Payment intent canceled")
	return nil
}

// handlePaymentMethodAttached handles payment method attached events
func (h *StripeWebhookHandler) handlePaymentMethodAttached(event *stripe.Event) error {
	var pm stripe.PaymentMethod
	if err := json.Unmarshal(event.Data.Raw, &pm); err != nil {
		return fmt.Errorf("failed to unmarshal payment method: %w", err)
	}

	logrus.WithField("payment_method_id", pm.ID).Info("Payment method attached")
	return nil
}

// handlePaymentMethodDetached handles payment method detached events
func (h *StripeWebhookHandler) handlePaymentMethodDetached(event *stripe.Event) error {
	var pm stripe.PaymentMethod
	if err := json.Unmarshal(event.Data.Raw, &pm); err != nil {
		return fmt.Errorf("failed to unmarshal payment method: %w", err)
	}

	// Delete payment method from database
	if err := h.paymentService.DeletePaymentMethod(pm.ID); err != nil {
		return fmt.Errorf("failed to delete payment method: %w", err)
	}

	logrus.WithField("payment_method_id", pm.ID).Info("Payment method detached")
	return nil
}

// handleSubscriptionCreated handles subscription created events
func (h *StripeWebhookHandler) handleSubscriptionCreated(event *stripe.Event) error {
	var sub stripe.Subscription
	if err := json.Unmarshal(event.Data.Raw, &sub); err != nil {
		return fmt.Errorf("failed to unmarshal subscription: %w", err)
	}

	// Create subscription in database
	if err := h.subscriptionService.CreateSubscriptionFromStripe(&sub); err != nil {
		return fmt.Errorf("failed to create subscription: %w", err)
	}

	logrus.WithField("subscription_id", sub.ID).Info("Subscription created")
	return nil
}

// handleSubscriptionUpdated handles subscription updated events
func (h *StripeWebhookHandler) handleSubscriptionUpdated(event *stripe.Event) error {
	var sub stripe.Subscription
	if err := json.Unmarshal(event.Data.Raw, &sub); err != nil {
		return fmt.Errorf("failed to unmarshal subscription: %w", err)
	}

	// Update subscription in database
	if err := h.subscriptionService.UpdateSubscriptionFromStripe(&sub); err != nil {
		return fmt.Errorf("failed to update subscription: %w", err)
	}

	logrus.WithField("subscription_id", sub.ID).Info("Subscription updated")
	return nil
}

// handleSubscriptionDeleted handles subscription deleted events
func (h *StripeWebhookHandler) handleSubscriptionDeleted(event *stripe.Event) error {
	var sub stripe.Subscription
	if err := json.Unmarshal(event.Data.Raw, &sub); err != nil {
		return fmt.Errorf("failed to unmarshal subscription: %w", err)
	}

	// Update subscription status in database
	if err := h.subscriptionService.UpdateSubscriptionStatus(sub.ID, "cancelled"); err != nil {
		return fmt.Errorf("failed to update subscription status: %w", err)
	}

	logrus.WithField("subscription_id", sub.ID).Info("Subscription deleted")
	return nil
}

// handleInvoicePaymentSucceeded handles invoice payment succeeded events
func (h *StripeWebhookHandler) handleInvoicePaymentSucceeded(event *stripe.Event) error {
	var invoice stripe.Invoice
	if err := json.Unmarshal(event.Data.Raw, &invoice); err != nil {
		return fmt.Errorf("failed to unmarshal invoice: %w", err)
	}

	// Update subscription status if needed
	if invoice.Subscription != nil {
		if err := h.subscriptionService.UpdateSubscriptionStatus(invoice.Subscription.ID, "active"); err != nil {
			return fmt.Errorf("failed to update subscription status: %w", err)
		}
	}

	logrus.WithField("invoice_id", invoice.ID).Info("Invoice payment succeeded")
	return nil
}

// handleInvoicePaymentFailed handles invoice payment failed events
func (h *StripeWebhookHandler) handleInvoicePaymentFailed(event *stripe.Event) error {
	var invoice stripe.Invoice
	if err := json.Unmarshal(event.Data.Raw, &invoice); err != nil {
		return fmt.Errorf("failed to unmarshal invoice: %w", err)
	}

	// Update subscription status if needed
	if invoice.Subscription != nil {
		if err := h.subscriptionService.UpdateSubscriptionStatus(invoice.Subscription.ID, "past_due"); err != nil {
			return fmt.Errorf("failed to update subscription status: %w", err)
		}
	}

	logrus.WithField("invoice_id", invoice.ID).Info("Invoice payment failed")
	return nil
}
