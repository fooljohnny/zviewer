package handlers

import (
	"net/http"
	"strconv"

	"zviewer-admin-service/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ModerationHandler handles moderation HTTP requests
type ModerationHandler struct {
	moderationService *services.ModerationService
}

// NewModerationHandler creates a new moderation handler
func NewModerationHandler(moderationService *services.ModerationService) *ModerationHandler {
	return &ModerationHandler{
		moderationService: moderationService,
	}
}

// GetModerationQueue handles GET /moderation/queue
func (h *ModerationHandler) GetModerationQueue(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	queue, total, err := h.moderationService.GetModerationQueue(page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	totalPages := (total + limit - 1) / limit

	c.JSON(http.StatusOK, gin.H{
		"queue":       queue,
		"total":       total,
		"page":        page,
		"limit":       limit,
		"total_pages": totalPages,
	})
}

// SubmitModerationDecision handles POST /moderation/review
func (h *ModerationHandler) SubmitModerationDecision(c *gin.Context) {
	var req struct {
		ContentID   uuid.UUID `json:"content_id" binding:"required"`
		Status      string    `json:"status" binding:"required"`
		Reason      string    `json:"reason,omitempty"`
		ReviewNotes string    `json:"review_notes,omitempty"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get moderator ID from context
	moderatorIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}

	moderatorID, err := uuid.Parse(moderatorIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid moderator ID"})
		return
	}

	err = h.moderationService.SubmitModerationDecision(req.ContentID, moderatorID, req.Status, req.Reason, req.ReviewNotes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// GetModerationHistory handles GET /moderation/history
func (h *ModerationHandler) GetModerationHistory(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	// Parse filters
	filters := make(map[string]interface{})
	if status := c.Query("status"); status != "" {
		filters["status"] = status
	}
	if moderatorIDStr := c.Query("moderator_id"); moderatorIDStr != "" {
		if moderatorID, err := uuid.Parse(moderatorIDStr); err == nil {
			filters["moderator_id"] = moderatorID
		}
	}

	history, total, err := h.moderationService.GetModerationHistory(page, limit, filters)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	totalPages := (total + limit - 1) / limit

	c.JSON(http.StatusOK, gin.H{
		"history":     history,
		"total":       total,
		"page":        page,
		"limit":       limit,
		"total_pages": totalPages,
	})
}

// BulkModeration handles POST /moderation/bulk-review
func (h *ModerationHandler) BulkModeration(c *gin.Context) {
	var req struct {
		ContentIDs  []uuid.UUID `json:"content_ids" binding:"required"`
		Status      string      `json:"status" binding:"required"`
		Reason      string      `json:"reason,omitempty"`
		ReviewNotes string      `json:"review_notes,omitempty"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get moderator ID from context
	moderatorIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}

	moderatorID, err := uuid.Parse(moderatorIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid moderator ID"})
		return
	}

	err = h.moderationService.BulkModeration(req.ContentIDs, moderatorID, req.Status, req.Reason, req.ReviewNotes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
