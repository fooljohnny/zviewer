package handlers

import (
	"net/http"

	"zviewer-payments-service/internal/middleware"
	"zviewer-payments-service/internal/models"
	"zviewer-payments-service/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// PaymentMethodHandler handles payment method HTTP requests
type PaymentMethodHandler struct {
	paymentMethodService *services.PaymentMethodService
}

// NewPaymentMethodHandler creates a new payment method handler
func NewPaymentMethodHandler(paymentMethodService *services.PaymentMethodService) *PaymentMethodHandler {
	return &PaymentMethodHandler{
		paymentMethodService: paymentMethodService,
	}
}

// CreatePaymentMethod handles POST /payment-methods
func (h *PaymentMethodHandler) CreatePaymentMethod(c *gin.Context) {
	userID := middleware.GetUserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}

	var req models.PaymentMethodCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	paymentMethod, err := h.paymentMethodService.CreatePaymentMethod(c.Request.Context(), userID, &req)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to create payment method")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create payment method", "details": err.Error()})
		return
	}

	middleware.LogWithContext(c).WithField("payment_method_id", paymentMethod.ID).Info("Payment method created successfully")
	c.JSON(http.StatusCreated, gin.H{"paymentMethod": paymentMethod})
}

// GetPaymentMethod handles GET /payment-methods/:id
func (h *PaymentMethodHandler) GetPaymentMethod(c *gin.Context) {
	paymentMethodID := c.Param("id")
	if paymentMethodID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payment method ID is required"})
		return
	}

	paymentMethod, err := h.paymentMethodService.GetPaymentMethod(c.Request.Context(), paymentMethodID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).WithField("payment_method_id", paymentMethodID).Error("Failed to get payment method")
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment method not found"})
		return
	}

	// Check if user owns this payment method
	userID := middleware.GetUserID(c)
	if paymentMethod.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"paymentMethod": paymentMethod})
}

// ListPaymentMethods handles GET /payment-methods
func (h *PaymentMethodHandler) ListPaymentMethods(c *gin.Context) {
	userID := middleware.GetUserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}

	// Parse query parameters
	query := &models.PaymentMethodQuery{}
	if err := c.ShouldBindQuery(query); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Invalid query parameters")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid query parameters", "details": err.Error()})
		return
	}

	// Set defaults
	query.SetDefaults()

	response, err := h.paymentMethodService.ListPaymentMethods(c.Request.Context(), userID, query)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to list payment methods")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list payment methods", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// UpdatePaymentMethod handles PUT /payment-methods/:id
func (h *PaymentMethodHandler) UpdatePaymentMethod(c *gin.Context) {
	paymentMethodID := c.Param("id")
	if paymentMethodID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payment method ID is required"})
		return
	}

	var req models.PaymentMethodUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	// Get the payment method first to check ownership
	paymentMethod, err := h.paymentMethodService.GetPaymentMethod(c.Request.Context(), paymentMethodID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).WithField("payment_method_id", paymentMethodID).Error("Failed to get payment method")
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment method not found"})
		return
	}

	// Check if user owns this payment method
	userID := middleware.GetUserID(c)
	if paymentMethod.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	updatedPaymentMethod, err := h.paymentMethodService.UpdatePaymentMethod(c.Request.Context(), paymentMethodID, &req)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to update payment method")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update payment method", "details": err.Error()})
		return
	}

	middleware.LogWithContext(c).WithField("payment_method_id", paymentMethodID).Info("Payment method updated successfully")
	c.JSON(http.StatusOK, gin.H{"paymentMethod": updatedPaymentMethod})
}

// DeletePaymentMethod handles DELETE /payment-methods/:id
func (h *PaymentMethodHandler) DeletePaymentMethod(c *gin.Context) {
	paymentMethodID := c.Param("id")
	if paymentMethodID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payment method ID is required"})
		return
	}

	// Get the payment method first to check ownership
	paymentMethod, err := h.paymentMethodService.GetPaymentMethod(c.Request.Context(), paymentMethodID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).WithField("payment_method_id", paymentMethodID).Error("Failed to get payment method")
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment method not found"})
		return
	}

	// Check if user owns this payment method
	userID := middleware.GetUserID(c)
	if paymentMethod.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	if err := h.paymentMethodService.DeletePaymentMethod(c.Request.Context(), paymentMethodID); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to delete payment method")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete payment method", "details": err.Error()})
		return
	}

	middleware.LogWithContext(c).WithField("payment_method_id", paymentMethodID).Info("Payment method deleted successfully")
	c.JSON(http.StatusOK, gin.H{"message": "Payment method deleted successfully"})
}

// GetDefaultPaymentMethod handles GET /payment-methods/default
func (h *PaymentMethodHandler) GetDefaultPaymentMethod(c *gin.Context) {
	userID := middleware.GetUserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}

	paymentMethod, err := h.paymentMethodService.GetDefaultPaymentMethod(c.Request.Context(), userID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to get default payment method")
		c.JSON(http.StatusNotFound, gin.H{"error": "No default payment method found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"paymentMethod": paymentMethod})
}

// SetDefaultPaymentMethod handles PUT /payment-methods/:id/default
func (h *PaymentMethodHandler) SetDefaultPaymentMethod(c *gin.Context) {
	paymentMethodID := c.Param("id")
	if paymentMethodID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payment method ID is required"})
		return
	}

	userID := middleware.GetUserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}

	if err := h.paymentMethodService.SetDefaultPaymentMethod(c.Request.Context(), userID, paymentMethodID); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to set default payment method")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set default payment method", "details": err.Error()})
		return
	}

	middleware.LogWithContext(c).WithFields(logrus.Fields{
		"user_id":           userID,
		"payment_method_id": paymentMethodID,
	}).Info("Default payment method set successfully")
	c.JSON(http.StatusOK, gin.H{"message": "Default payment method set successfully"})
}
