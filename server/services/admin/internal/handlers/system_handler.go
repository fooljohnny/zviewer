package handlers

import (
	"net/http"
	"strconv"

	"zviewer-admin-service/internal/services"

	"github.com/gin-gonic/gin"
)

// SystemHandler handles system management HTTP requests
type SystemHandler struct {
	systemService *services.SystemService
}

// NewSystemHandler creates a new system handler
func NewSystemHandler(systemService *services.SystemService) *SystemHandler {
	return &SystemHandler{
		systemService: systemService,
	}
}

// GetOverviewStats handles GET /stats/overview
func (h *SystemHandler) GetOverviewStats(c *gin.Context) {
	stats, err := h.systemService.GetOverviewStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// GetUserStats handles GET /stats/users
func (h *SystemHandler) GetUserStats(c *gin.Context) {
	stats, err := h.systemService.GetUserStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// GetContentStats handles GET /stats/content
func (h *SystemHandler) GetContentStats(c *gin.Context) {
	stats, err := h.systemService.GetContentStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// GetPaymentStats handles GET /stats/payments
func (h *SystemHandler) GetPaymentStats(c *gin.Context) {
	stats, err := h.systemService.GetPaymentStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// GetAuditLogs handles GET /logs/audit
func (h *SystemHandler) GetAuditLogs(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	// Parse filters
	filters := make(map[string]interface{})
	if actionType := c.Query("action_type"); actionType != "" {
		filters["action_type"] = actionType
	}
	if targetType := c.Query("target_type"); targetType != "" {
		filters["target_type"] = targetType
	}

	logs, total, err := h.systemService.GetAuditLogs(page, limit, filters)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	totalPages := (total + limit - 1) / limit

	c.JSON(http.StatusOK, gin.H{
		"logs":        logs,
		"total":       total,
		"page":        page,
		"limit":       limit,
		"total_pages": totalPages,
	})
}
