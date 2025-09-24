package handlers

import (
	"net/http"

	"zviewer-payments-service/internal/middleware"
	"zviewer-payments-service/internal/models"
	"zviewer-payments-service/internal/services"

	"github.com/gin-gonic/gin"
)

// PaymentHandler handles payment HTTP requests
type PaymentHandler struct {
	paymentService *services.PaymentService
}

// NewPaymentHandler creates a new payment handler
func NewPaymentHandler(paymentService *services.PaymentService) *PaymentHandler {
	return &PaymentHandler{
		paymentService: paymentService,
	}
}

// CreatePayment handles POST /payments
func (h *PaymentHandler) CreatePayment(c *gin.Context) {
	userID := middleware.GetUserID(c)
	if userID == "" {
		middleware.HandleUnauthorizedError(c, "User ID not found")
		return
	}

	var req models.PaymentCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.HandleValidationError(c, err)
		return
	}

	payment, err := h.paymentService.CreatePayment(c.Request.Context(), userID, &req)
	if err != nil {
		middleware.HandleError(c, err, http.StatusInternalServerError, "Failed to create payment")
		return
	}

	middleware.LogWithContext(c).WithField("payment_id", payment.ID).Info("Payment created successfully")
	c.JSON(http.StatusCreated, gin.H{"payment": payment})
}

// GetPayment handles GET /payments/:id
func (h *PaymentHandler) GetPayment(c *gin.Context) {
	paymentID := c.Param("id")
	if paymentID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payment ID is required"})
		return
	}

	payment, err := h.paymentService.GetPayment(c.Request.Context(), paymentID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).WithField("payment_id", paymentID).Error("Failed to get payment")
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found"})
		return
	}

	// Check if user owns this payment
	userID := middleware.GetUserID(c)
	if payment.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"payment": payment})
}

// ListPayments handles GET /payments
func (h *PaymentHandler) ListPayments(c *gin.Context) {
	userID := middleware.GetUserID(c)
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}

	// Parse query parameters
	query := &models.PaymentQuery{}
	if err := c.ShouldBindQuery(query); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Invalid query parameters")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid query parameters", "details": err.Error()})
		return
	}

	// Set defaults
	query.SetDefaults()

	response, err := h.paymentService.ListPayments(c.Request.Context(), userID, query)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to list payments")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list payments", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// ProcessRefund handles POST /payments/:id/refund
func (h *PaymentHandler) ProcessRefund(c *gin.Context) {
	paymentID := c.Param("id")
	if paymentID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payment ID is required"})
		return
	}

	var req models.PaymentRefundRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Invalid request body")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	// Get the payment first to check ownership
	payment, err := h.paymentService.GetPayment(c.Request.Context(), paymentID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).WithField("payment_id", paymentID).Error("Failed to get payment")
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found"})
		return
	}

	// Check if user owns this payment
	userID := middleware.GetUserID(c)
	if payment.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	updatedPayment, err := h.paymentService.ProcessRefund(c.Request.Context(), paymentID, &req)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to process refund")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process refund", "details": err.Error()})
		return
	}

	middleware.LogWithContext(c).WithField("payment_id", paymentID).Info("Refund processed successfully")
	c.JSON(http.StatusOK, gin.H{"payment": updatedPayment})
}

// GetStats handles GET /payments/stats (admin only)
func (h *PaymentHandler) GetStats(c *gin.Context) {
	stats, err := h.paymentService.GetPaymentStats(c.Request.Context())
	if err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to get payment stats")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get payment stats", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"stats": stats})
}

// DeletePayment handles DELETE /payments/:id
func (h *PaymentHandler) DeletePayment(c *gin.Context) {
	paymentID := c.Param("id")
	if paymentID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payment ID is required"})
		return
	}

	// Get the payment first to check ownership
	payment, err := h.paymentService.GetPayment(c.Request.Context(), paymentID)
	if err != nil {
		middleware.LogWithContext(c).WithError(err).WithField("payment_id", paymentID).Error("Failed to get payment")
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found"})
		return
	}

	// Check if user owns this payment
	userID := middleware.GetUserID(c)
	if payment.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	if err := h.paymentService.DeletePayment(c.Request.Context(), paymentID); err != nil {
		middleware.LogWithContext(c).WithError(err).Error("Failed to delete payment")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete payment", "details": err.Error()})
		return
	}

	middleware.LogWithContext(c).WithField("payment_id", paymentID).Info("Payment deleted successfully")
	c.JSON(http.StatusOK, gin.H{"message": "Payment deleted successfully"})
}
