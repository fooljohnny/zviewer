package handlers

import (
	"net/http"

	"zviewer-payments-service/internal/middleware"
	"zviewer-payments-service/internal/models"
	"zviewer-payments-service/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// SubscriptionHandler handles subscription HTTP requests
type SubscriptionHandler struct {
	subscriptionService *services.SubscriptionService
}

// NewSubscriptionHandler creates a new subscription handler
func NewSubscriptionHandler(subscriptionService *services.SubscriptionService) *SubscriptionHandler {
	return &SubscriptionHandler{
		subscriptionService: subscriptionService,
	}
}

// CreateSubscription handles POST /subscriptions
func (h *SubscriptionHandler) CreateSubscription(c *gin.Context) {
	userID := middleware.GetUserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}

	var req models.SubscriptionCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	subscription, err := h.subscriptionService.CreateSubscription(c.Request.Context(), userID, &req)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to create subscription")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create subscription", "details": err.Error()})
		return
	}

	middleware.LogWithContext(c).WithField("subscription_id", subscription.ID).Info("Subscription created successfully")
	c.JSON(http.StatusCreated, gin.H{"subscription": subscription})
}

// GetSubscription handles GET /subscriptions/:id
func (h *SubscriptionHandler) GetSubscription(c *gin.Context) {
	subscriptionID := c.Param("id")
	if subscriptionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Subscription ID is required"})
		return
	}

	subscription, err := h.subscriptionService.GetSubscription(c.Request.Context(), subscriptionID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).WithField("subscription_id", subscriptionID).Error("Failed to get subscription")
		c.JSON(http.StatusNotFound, gin.H{"error": "Subscription not found"})
		return
	}

	// Check if user owns this subscription
	userID := middleware.GetUserID(c)
	if subscription.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"subscription": subscription})
}

// ListSubscriptions handles GET /subscriptions
func (h *SubscriptionHandler) ListSubscriptions(c *gin.Context) {
	userID := middleware.GetUserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}

	// Parse query parameters
	query := &models.SubscriptionQuery{}
	if err := c.ShouldBindQuery(query); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Invalid query parameters")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid query parameters", "details": err.Error()})
		return
	}

	// Set defaults
	query.SetDefaults()

	response, err := h.subscriptionService.ListSubscriptions(c.Request.Context(), userID, query)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to list subscriptions")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list subscriptions", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// UpdateSubscription handles PUT /subscriptions/:id
func (h *SubscriptionHandler) UpdateSubscription(c *gin.Context) {
	subscriptionID := c.Param("id")
	if subscriptionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Subscription ID is required"})
		return
	}

	var req models.SubscriptionUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	// Get the subscription first to check ownership
	subscription, err := h.subscriptionService.GetSubscription(c.Request.Context(), subscriptionID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).WithField("subscription_id", subscriptionID).Error("Failed to get subscription")
		c.JSON(http.StatusNotFound, gin.H{"error": "Subscription not found"})
		return
	}

	// Check if user owns this subscription
	userID := middleware.GetUserID(c)
	if subscription.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	updatedSubscription, err := h.subscriptionService.UpdateSubscription(c.Request.Context(), subscriptionID, &req)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to update subscription")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update subscription", "details": err.Error()})
		return
	}

	middleware.LogWithContext(c).WithField("subscription_id", subscriptionID).Info("Subscription updated successfully")
	c.JSON(http.StatusOK, gin.H{"subscription": updatedSubscription})
}

// CancelSubscription handles DELETE /subscriptions/:id
func (h *SubscriptionHandler) CancelSubscription(c *gin.Context) {
	subscriptionID := c.Param("id")
	if subscriptionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Subscription ID is required"})
		return
	}

	// Get the subscription first to check ownership
	subscription, err := h.subscriptionService.GetSubscription(c.Request.Context(), subscriptionID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).WithField("subscription_id", subscriptionID).Error("Failed to get subscription")
		c.JSON(http.StatusNotFound, gin.H{"error": "Subscription not found"})
		return
	}

	// Check if user owns this subscription
	userID := middleware.GetUserID(c)
	if subscription.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	if err := h.subscriptionService.CancelSubscription(c.Request.Context(), subscriptionID); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to cancel subscription")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to cancel subscription", "details": err.Error()})
		return
	}

	middleware.LogWithContext(c).WithField("subscription_id", subscriptionID).Info("Subscription cancelled successfully")
	c.JSON(http.StatusOK, gin.H{"message": "Subscription cancelled successfully"})
}

// GetSubscriptionStats handles GET /subscriptions/stats (admin only)
func (h *SubscriptionHandler) GetSubscriptionStats(c *gin.Context) {
	stats, err := h.subscriptionService.GetSubscriptionStats(c.Request.Context())
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to get subscription stats")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get subscription stats", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"stats": stats})
}

// DeleteSubscription handles DELETE /subscriptions/:id (soft delete)
func (h *SubscriptionHandler) DeleteSubscription(c *gin.Context) {
	subscriptionID := c.Param("id")
	if subscriptionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Subscription ID is required"})
		return
	}

	// Get the subscription first to check ownership
	subscription, err := h.subscriptionService.GetSubscription(c.Request.Context(), subscriptionID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).WithField("subscription_id", subscriptionID).Error("Failed to get subscription")
		c.JSON(http.StatusNotFound, gin.H{"error": "Subscription not found"})
		return
	}

	// Check if user owns this subscription
	userID := middleware.GetUserID(c)
	if subscription.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	if err := h.subscriptionService.DeleteSubscription(c.Request.Context(), subscriptionID); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to delete subscription")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete subscription", "details": err.Error()})
		return
	}

	middleware.LogWithContext(c).WithField("subscription_id", subscriptionID).Info("Subscription deleted successfully")
	c.JSON(http.StatusOK, gin.H{"message": "Subscription deleted successfully"})
}
