package handlers

import (
	"zviewer-payments-service/internal/config"
	"zviewer-payments-service/internal/services"
	"zviewer-payments-service/internal/webhooks"

	"github.com/gin-gonic/gin"
)

// WebhookHandler handles webhook HTTP requests
type WebhookHandler struct {
	stripeWebhookHandler *webhooks.StripeWebhookHandler
}

// NewWebhookHandler creates a new webhook handler
func NewWebhookHandler(
	stripeService *services.StripeService,
	paymentService *services.PaymentService,
	subscriptionService *services.SubscriptionService,
	config *config.Config,
) *WebhookHandler {
	return &WebhookHandler{
		stripeWebhookHandler: webhooks.NewStripeWebhookHandler(stripeService, paymentService, subscriptionService, config),
	}
}

// HandleStripeWebhook handles POST /webhooks/stripe
func (h *WebhookHandler) HandleStripeWebhook(c *gin.Context) {
	h.stripeWebhookHandler.HandleWebhook(c)
}
