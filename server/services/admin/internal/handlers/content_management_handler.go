package handlers

import (
	"net/http"
	"strconv"

	"zviewer-admin-service/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ContentManagementHandler handles content management HTTP requests
type ContentManagementHandler struct {
	contentManagementService *services.ContentManagementService
}

// NewContentManagementHandler creates a new content management handler
func NewContentManagementHandler(contentManagementService *services.ContentManagementService) *ContentManagementHandler {
	return &ContentManagementHandler{
		contentManagementService: contentManagementService,
	}
}

// ListContent handles GET /content
func (h *ContentManagementHandler) ListContent(c *gin.Context) {
	// Parse pagination parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	// Parse filters
	filters := make(map[string]string)
	if status := c.Query("status"); status != "" {
		filters["status"] = status
	}
	if contentType := c.Query("type"); contentType != "" {
		filters["type"] = contentType
	}

	// Call service
	content, total, err := h.contentManagementService.ListContent(page, limit, filters)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Calculate pagination info
	totalPages := (total + limit - 1) / limit

	c.JSON(http.StatusOK, gin.H{
		"content":     content,
		"total":       total,
		"page":        page,
		"limit":       limit,
		"total_pages": totalPages,
	})
}

// GetContent handles GET /content/:id
func (h *ContentManagementHandler) GetContent(c *gin.Context) {
	contentIDStr := c.Param("id")
	contentID, err := uuid.Parse(contentIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid content ID"})
		return
	}

	content, err := h.contentManagementService.GetContent(contentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, content)
}

// UpdateContentStatus handles PUT /content/:id/status
func (h *ContentManagementHandler) UpdateContentStatus(c *gin.Context) {
	contentIDStr := c.Param("id")
	contentID, err := uuid.Parse(contentIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid content ID"})
		return
	}

	var req struct {
		Status string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	content, err := h.contentManagementService.UpdateContentStatus(contentID, req.Status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, content)
}

// FlagContent handles POST /content/:id/flag
func (h *ContentManagementHandler) FlagContent(c *gin.Context) {
	contentIDStr := c.Param("id")
	contentID, err := uuid.Parse(contentIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid content ID"})
		return
	}

	var req struct {
		Reason string   `json:"reason" binding:"required"`
		Flags  []string `json:"flags" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.contentManagementService.FlagContent(contentID, req.Reason, req.Flags)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// GetFlaggedContent handles GET /content/flagged
func (h *ContentManagementHandler) GetFlaggedContent(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	content, total, err := h.contentManagementService.GetFlaggedContent(page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	totalPages := (total + limit - 1) / limit

	c.JSON(http.StatusOK, gin.H{
		"content":     content,
		"total":       total,
		"page":        page,
		"limit":       limit,
		"total_pages": totalPages,
	})
}

// BulkAction handles POST /content/bulk-action
func (h *ContentManagementHandler) BulkAction(c *gin.Context) {
	var req struct {
		Action     string      `json:"action" binding:"required"`
		ContentIDs []uuid.UUID `json:"content_ids" binding:"required"`
		Reason     string      `json:"reason,omitempty"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.contentManagementService.BulkAction(req.Action, req.ContentIDs, req.Reason)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// GetContentStats handles GET /content/stats
func (h *ContentManagementHandler) GetContentStats(c *gin.Context) {
	stats, err := h.contentManagementService.GetContentStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}
