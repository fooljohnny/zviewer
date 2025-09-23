package services

import (
	"fmt"
	"html"
	"regexp"
	"strings"
	"time"

	"zviewer-comments-service/internal/config"
	"zviewer-comments-service/internal/models"
	"zviewer-comments-service/internal/repositories"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

// CommentService handles business logic for comments
type CommentService struct {
	commentRepo *repositories.CommentRepository
	config      *config.Config
}

// NewCommentService creates a new comment service
func NewCommentService(commentRepo *repositories.CommentRepository, config *config.Config) *CommentService {
	return &CommentService{
		commentRepo: commentRepo,
		config:      config,
	}
}

// CreateComment creates a new comment
func (s *CommentService) CreateComment(req models.CommentCreateRequest, userID string) (*models.Comment, error) {
	// Validate input
	if err := s.validateCommentContent(req.Content); err != nil {
		return nil, err
	}

	// Validate media item exists
	if err := s.commentRepo.ValidateMediaExists(req.MediaItemID); err != nil {
		return nil, fmt.Errorf("media validation failed: %w", err)
	}

	// Validate user exists
	if err := s.commentRepo.ValidateUserExists(userID); err != nil {
		return nil, fmt.Errorf("user validation failed: %w", err)
	}

	// Validate parent comment if provided
	if req.ParentID != nil && *req.ParentID != "" {
		if err := s.commentRepo.ValidateParentComment(*req.ParentID); err != nil {
			return nil, fmt.Errorf("parent comment validation failed: %w", err)
		}
	}

	// Create comment
	comment := &models.Comment{
		ID:          uuid.New().String(),
		UserID:      userID,
		MediaItemID: req.MediaItemID,
		ParentID:    req.ParentID,
		Content:     s.sanitizeContent(req.Content),
		Status:      models.CommentStatusActive,
		IsEdited:    false,
	}
	comment.SetTimestamps()

	// Apply profanity filter if enabled
	if s.config.EnableProfanityFilter {
		if s.containsProfanity(comment.Content) {
			comment.Status = models.CommentStatusPending
			logrus.Warnf("Comment flagged for profanity: %s", comment.ID)
		}
	}

	// Save to database
	if err := s.commentRepo.Create(comment); err != nil {
		return nil, fmt.Errorf("failed to create comment: %w", err)
	}

	logrus.Infof("Comment created successfully: %s", comment.ID)
	return comment, nil
}

// GetComment retrieves a comment by ID
func (s *CommentService) GetComment(id string) (*models.Comment, error) {
	comment, err := s.commentRepo.GetByID(id)
	if err != nil {
		return nil, err
	}

	// Don't return deleted comments unless specifically requested
	if comment.IsDeleted() {
		return nil, fmt.Errorf("comment not found")
	}

	return comment, nil
}

// UpdateComment updates a comment
func (s *CommentService) UpdateComment(id string, req models.CommentUpdateRequest, userID string) (*models.Comment, error) {
	// Get existing comment
	comment, err := s.commentRepo.GetByID(id)
	if err != nil {
		return nil, err
	}

	// Check ownership
	if comment.UserID != userID {
		return nil, fmt.Errorf("not authorized to update this comment")
	}

	// Check if comment can be edited
	if !comment.CanBeEdited() {
		return nil, fmt.Errorf("comment cannot be edited")
	}

	// Validate new content
	if err := s.validateCommentContent(req.Content); err != nil {
		return nil, err
	}

	// Update comment
	comment.Content = s.sanitizeContent(req.Content)
	comment.SetEdited()
	comment.Status = models.CommentStatusActive

	// Apply profanity filter if enabled
	if s.config.EnableProfanityFilter {
		if s.containsProfanity(comment.Content) {
			comment.Status = models.CommentStatusPending
			logrus.Warnf("Updated comment flagged for profanity: %s", comment.ID)
		}
	}

	// Save to database
	if err := s.commentRepo.Update(comment); err != nil {
		return nil, fmt.Errorf("failed to update comment: %w", err)
	}

	logrus.Infof("Comment updated successfully: %s", comment.ID)
	return comment, nil
}

// DeleteComment soft deletes a comment
func (s *CommentService) DeleteComment(id string, userID string, isAdmin bool) error {
	// Get existing comment
	comment, err := s.commentRepo.GetByID(id)
	if err != nil {
		return err
	}

	// Check authorization
	if comment.UserID != userID && !isAdmin {
		return fmt.Errorf("not authorized to delete this comment")
	}

	// Check if comment can be deleted
	if !comment.CanBeDeleted() {
		return fmt.Errorf("comment cannot be deleted")
	}

	// Soft delete comment
	if err := s.commentRepo.Delete(id); err != nil {
		return fmt.Errorf("failed to delete comment: %w", err)
	}

	logrus.Infof("Comment deleted successfully: %s", comment.ID)
	return nil
}

// ListComments retrieves comments with pagination and filtering
func (s *CommentService) ListComments(query models.CommentQuery) (*models.CommentListResponse, error) {
	comments, total, err := s.commentRepo.List(query)
	if err != nil {
		return nil, fmt.Errorf("failed to list comments: %w", err)
	}

	hasMore := int64(query.Page*query.Limit) < total

	response := &models.CommentListResponse{
		Comments: comments,
		Total:    total,
		Page:     query.Page,
		Limit:    query.Limit,
		HasMore:  hasMore,
	}

	return response, nil
}

// GetCommentsByMedia retrieves comments for a specific media item
func (s *CommentService) GetCommentsByMedia(mediaID string, query models.CommentQuery) (*models.CommentListResponse, error) {
	comments, total, err := s.commentRepo.GetByMediaID(mediaID, query)
	if err != nil {
		return nil, fmt.Errorf("failed to get comments by media: %w", err)
	}

	hasMore := int64(query.Page*query.Limit) < total

	response := &models.CommentListResponse{
		Comments: comments,
		Total:    total,
		Page:     query.Page,
		Limit:    query.Limit,
		HasMore:  hasMore,
	}

	return response, nil
}

// ReplyToComment creates a reply to a comment
func (s *CommentService) ReplyToComment(parentID string, req models.CommentReplyRequest, userID string) (*models.Comment, error) {
	// Validate parent comment exists
	parentComment, err := s.commentRepo.GetByID(parentID)
	if err != nil {
		return nil, fmt.Errorf("parent comment not found: %w", err)
	}

	// Check if parent comment is active
	if !parentComment.IsActive() {
		return nil, fmt.Errorf("cannot reply to inactive comment")
	}

	// Create reply
	replyReq := models.CommentCreateRequest{
		MediaItemID: parentComment.MediaItemID,
		ParentID:    &parentID,
		Content:     req.Content,
	}

	return s.CreateComment(replyReq, userID)
}

// GetReplies retrieves replies to a comment
func (s *CommentService) GetReplies(parentID string, query models.CommentQuery) (*models.CommentListResponse, error) {
	comments, total, err := s.commentRepo.GetReplies(parentID, query)
	if err != nil {
		return nil, fmt.Errorf("failed to get replies: %w", err)
	}

	hasMore := int64(query.Page*query.Limit) < total

	response := &models.CommentListResponse{
		Comments: comments,
		Total:    total,
		Page:     query.Page,
		Limit:    query.Limit,
		HasMore:  hasMore,
	}

	return response, nil
}

// GetStats retrieves comment statistics
func (s *CommentService) GetStats() (*models.CommentStats, error) {
	return s.commentRepo.GetStats()
}

// GetUserStats retrieves user comment statistics
func (s *CommentService) GetUserStats(userID string) (*models.UserCommentStats, error) {
	return s.commentRepo.GetUserStats(userID)
}

// GetMediaStats retrieves media comment statistics
func (s *CommentService) GetMediaStats(mediaID string) (*models.MediaCommentStats, error) {
	return s.commentRepo.GetMediaStats(mediaID)
}

// validateCommentContent validates comment content
func (s *CommentService) validateCommentContent(content string) error {
	if len(strings.TrimSpace(content)) == 0 {
		return fmt.Errorf("comment content cannot be empty")
	}

	if len(content) > s.config.MaxCommentLength {
		return fmt.Errorf("comment content cannot exceed %d characters", s.config.MaxCommentLength)
	}

	// Check for minimum content length
	if len(strings.TrimSpace(content)) < 3 {
		return fmt.Errorf("comment content must be at least 3 characters")
	}

	return nil
}

// sanitizeContent sanitizes comment content
func (s *CommentService) sanitizeContent(content string) string {
	// Trim whitespace
	content = strings.TrimSpace(content)

	// HTML escape to prevent XSS attacks
	content = html.EscapeString(content)

	// Remove excessive whitespace
	re := regexp.MustCompile(`\s+`)
	content = re.ReplaceAllString(content, " ")

	// Remove potentially dangerous HTML tags and attributes
	dangerousTags := []string{"<script", "</script>", "<iframe", "</iframe>", "<object", "</object>", "<embed", "</embed>"}
	for _, tag := range dangerousTags {
		content = strings.ReplaceAll(content, tag, "")
	}

	return content
}

// containsProfanity checks if content contains profanity
func (s *CommentService) containsProfanity(content string) bool {
	// Simple profanity filter - in production, use a proper profanity detection library
	profanityWords := []string{
		"spam", "scam", "fake", "bot", // Add more as needed
	}

	content = strings.ToLower(content)
	for _, word := range profanityWords {
		if strings.Contains(content, word) {
			return true
		}
	}

	return false
}

// ModerateComment moderates a comment (admin only)
func (s *CommentService) ModerateComment(commentID string, action string, reason string, moderatorID string) error {
	comment, err := s.commentRepo.GetByID(commentID)
	if err != nil {
		return err
	}

	switch action {
	case "approve":
		comment.Status = models.CommentStatusActive
	case "reject":
		comment.Status = models.CommentStatusModerated
	case "delete":
		comment.Status = models.CommentStatusDeleted
		comment.SoftDelete()
	default:
		return fmt.Errorf("invalid moderation action: %s", action)
	}

	comment.UpdatedAt = time.Now()

	if err := s.commentRepo.Update(comment); err != nil {
		return fmt.Errorf("failed to moderate comment: %w", err)
	}

	logrus.Infof("Comment moderated: %s, action: %s, moderator: %s", commentID, action, moderatorID)
	return nil
}
