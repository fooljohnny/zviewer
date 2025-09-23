package handlers

import (
	"net/http"

	"zviewer-comments-service/internal/middleware"
	"zviewer-comments-service/internal/models"
	"zviewer-comments-service/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// CommentHandler handles HTTP requests for comment operations
type CommentHandler struct {
	commentService *services.CommentService
}

// NewCommentHandler creates a new comment handler
func NewCommentHandler(commentService *services.CommentService) *CommentHandler {
	return &CommentHandler{
		commentService: commentService,
	}
}

// CreateComment handles creating a new comment
func (h *CommentHandler) CreateComment(c *gin.Context) {
	// Get user info from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "User ID not found"})
		return
	}

	// Parse request
	var req models.CommentCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid request data", "error": err.Error()})
		return
	}

	// Create comment
	comment, err := h.commentService.CreateComment(req, userID.(string))
	if err != nil {
		middleware.LogWithContext(c).Errorf("Failed to create comment: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to create comment", "error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, comment)
}

// GetComment handles getting a comment by ID
func (h *CommentHandler) GetComment(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Comment ID required"})
		return
	}

	comment, err := h.commentService.GetComment(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Comment not found"})
		return
	}

	c.JSON(http.StatusOK, comment)
}

// UpdateComment handles updating a comment
func (h *CommentHandler) UpdateComment(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Comment ID required"})
		return
	}

	// Get user info from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "User ID not found"})
		return
	}

	// Parse request
	var req models.CommentUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid request data", "error": err.Error()})
		return
	}

	// Update comment
	comment, err := h.commentService.UpdateComment(id, req, userID.(string))
	if err != nil {
		middleware.LogWithContext(c).Errorf("Failed to update comment: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to update comment", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, comment)
}

// DeleteComment handles deleting a comment
func (h *CommentHandler) DeleteComment(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Comment ID required"})
		return
	}

	// Get user info from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "User ID not found"})
		return
	}

	// Check if user is admin
	userRole, _ := c.Get("user_role")
	isAdmin := userRole == "admin"

	// Delete comment
	err := h.commentService.DeleteComment(id, userID.(string), isAdmin)
	if err != nil {
		logrus.Errorf("Failed to delete comment: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to delete comment", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Comment deleted successfully"})
}

// ListComments handles listing comments with pagination and filtering
func (h *CommentHandler) ListComments(c *gin.Context) {
	// Parse query parameters
	var query models.CommentQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid query parameters", "error": err.Error()})
		return
	}

	// List comments
	response, err := h.commentService.ListComments(query)
	if err != nil {
		logrus.Errorf("Failed to list comments: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to list comments", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GetCommentsByMedia handles getting comments for a specific media item
func (h *CommentHandler) GetCommentsByMedia(c *gin.Context) {
	mediaID := c.Param("mediaId")
	if mediaID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Media ID required"})
		return
	}

	// Parse query parameters
	var query models.CommentQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid query parameters", "error": err.Error()})
		return
	}

	// Get comments by media
	response, err := h.commentService.GetCommentsByMedia(mediaID, query)
	if err != nil {
		logrus.Errorf("Failed to get comments by media: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to get comments by media", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// ReplyToComment handles replying to a comment
func (h *CommentHandler) ReplyToComment(c *gin.Context) {
	parentID := c.Param("id")
	if parentID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Parent comment ID required"})
		return
	}

	// Get user info from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "User ID not found"})
		return
	}

	// Parse request
	var req models.CommentReplyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid request data", "error": err.Error()})
		return
	}

	// Create reply
	comment, err := h.commentService.ReplyToComment(parentID, req, userID.(string))
	if err != nil {
		logrus.Errorf("Failed to create reply: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to create reply", "error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, comment)
}

// GetReplies handles getting replies to a comment
func (h *CommentHandler) GetReplies(c *gin.Context) {
	parentID := c.Param("id")
	if parentID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Parent comment ID required"})
		return
	}

	// Parse query parameters
	var query models.CommentQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid query parameters", "error": err.Error()})
		return
	}

	// Get replies
	response, err := h.commentService.GetReplies(parentID, query)
	if err != nil {
		logrus.Errorf("Failed to get replies: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to get replies", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GetStats handles getting comment statistics (admin only)
func (h *CommentHandler) GetStats(c *gin.Context) {
	stats, err := h.commentService.GetStats()
	if err != nil {
		logrus.Errorf("Failed to get comment stats: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to get comment statistics", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// GetUserStats handles getting user comment statistics
func (h *CommentHandler) GetUserStats(c *gin.Context) {
	userID := c.Param("userId")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "User ID required"})
		return
	}

	stats, err := h.commentService.GetUserStats(userID)
	if err != nil {
		logrus.Errorf("Failed to get user stats: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to get user statistics", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// GetMediaStats handles getting media comment statistics
func (h *CommentHandler) GetMediaStats(c *gin.Context) {
	mediaID := c.Param("mediaId")
	if mediaID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Media ID required"})
		return
	}

	stats, err := h.commentService.GetMediaStats(mediaID)
	if err != nil {
		logrus.Errorf("Failed to get media stats: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to get media statistics", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// ModerateComment handles comment moderation (admin only)
func (h *CommentHandler) ModerateComment(c *gin.Context) {
	commentID := c.Param("id")
	if commentID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Comment ID required"})
		return
	}

	// Get moderator info from context
	moderatorID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Moderator ID not found"})
		return
	}

	// Parse request
	var req struct {
		Action string `json:"action" binding:"required"`
		Reason string `json:"reason"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid request data", "error": err.Error()})
		return
	}

	// Moderate comment
	err := h.commentService.ModerateComment(commentID, req.Action, req.Reason, moderatorID.(string))
	if err != nil {
		logrus.Errorf("Failed to moderate comment: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to moderate comment", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Comment moderated successfully"})
}
