package models

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

// Comment represents a comment in the system
type Comment struct {
	ID          string        `json:"id" db:"id"`
	UserID      string        `json:"userId" db:"user_id"`
	MediaItemID string        `json:"mediaItemId" db:"media_item_id"`
	ParentID    *string       `json:"parentId,omitempty" db:"parent_id"`
	Content     string        `json:"content" db:"content"`
	Status      CommentStatus `json:"status" db:"status"`
	CreatedAt   time.Time     `json:"createdAt" db:"created_at"`
	UpdatedAt   time.Time     `json:"updatedAt" db:"updated_at"`
	DeletedAt   *time.Time    `json:"deletedAt,omitempty" db:"deleted_at"`
	// Computed fields
	UserName     string `json:"userName,omitempty" db:"user_name"`
	RepliesCount int    `json:"repliesCount,omitempty" db:"replies_count"`
	IsEdited     bool   `json:"isEdited" db:"is_edited"`
}

// CommentStatus represents the status of a comment
type CommentStatus string

const (
	CommentStatusActive    CommentStatus = "active"
	CommentStatusDeleted   CommentStatus = "deleted"
	CommentStatusModerated CommentStatus = "moderated"
	CommentStatusPending   CommentStatus = "pending"
)

// CommentCreateRequest represents the request for creating a comment
type CommentCreateRequest struct {
	MediaItemID string  `json:"mediaItemId" binding:"required"`
	ParentID    *string `json:"parentId,omitempty"`
	Content     string  `json:"content" binding:"required,min=1,max=1000"`
}

// CommentUpdateRequest represents the request for updating a comment
type CommentUpdateRequest struct {
	Content string `json:"content" binding:"required,min=1,max=1000"`
}

// CommentReplyRequest represents the request for replying to a comment
type CommentReplyRequest struct {
	Content string `json:"content" binding:"required,min=1,max=1000"`
}

// CommentListResponse represents the response for listing comments
type CommentListResponse struct {
	Comments []Comment `json:"comments"`
	Total    int64     `json:"total"`
	Page     int       `json:"page"`
	Limit    int       `json:"limit"`
	HasMore  bool      `json:"hasMore"`
}

// CommentQuery represents query parameters for listing comments
type CommentQuery struct {
	Page      int    `form:"page" binding:"min=1"`
	Limit     int    `form:"limit" binding:"min=1,max=100"`
	MediaID   string `form:"mediaId"`
	UserID    string `form:"userId"`
	Status    string `form:"status"`
	ParentID  string `form:"parentId"`
	SortBy    string `form:"sortBy"`
	SortOrder string `form:"sortOrder"`
}

// SetDefaults sets default values for the query
func (q *CommentQuery) SetDefaults() {
	if q.Page <= 0 {
		q.Page = 1
	}
	if q.Limit <= 0 {
		q.Limit = 20
	}
	if q.SortBy == "" {
		q.SortBy = "created_at"
	}
	if q.SortOrder == "" {
		q.SortOrder = "desc"
	}
}

// CommentStats represents comment statistics
type CommentStats struct {
	TotalComments     int64 `json:"totalComments"`
	ActiveComments    int64 `json:"activeComments"`
	DeletedComments   int64 `json:"deletedComments"`
	ModeratedComments int64 `json:"moderatedComments"`
	PendingComments   int64 `json:"pendingComments"`
	CommentsToday     int64 `json:"commentsToday"`
	CommentsThisWeek  int64 `json:"commentsThisWeek"`
	CommentsThisMonth int64 `json:"commentsThisMonth"`
}

// UserCommentStats represents user-specific comment statistics
type UserCommentStats struct {
	UserID         string     `json:"userId"`
	UserName       string     `json:"userName"`
	TotalComments  int64      `json:"totalComments"`
	ActiveComments int64      `json:"activeComments"`
	LastCommentAt  *time.Time `json:"lastCommentAt"`
}

// MediaCommentStats represents media-specific comment statistics
type MediaCommentStats struct {
	MediaID        string     `json:"mediaId"`
	TotalComments  int64      `json:"totalComments"`
	ActiveComments int64      `json:"activeComments"`
	LastCommentAt  *time.Time `json:"lastCommentAt"`
}

// CommentModeration represents comment moderation data
type CommentModeration struct {
	CommentID      string        `json:"commentId"`
	ModeratedBy    string        `json:"moderatedBy"`
	ModeratedAt    time.Time     `json:"moderatedAt"`
	Reason         string        `json:"reason"`
	Action         string        `json:"action"` // "approve", "reject", "delete"
	PreviousStatus CommentStatus `json:"previousStatus"`
}

// Validate validates the comment content
func (c *Comment) Validate() error {
	if len(c.Content) == 0 {
		return fmt.Errorf("comment content cannot be empty")
	}
	if len(c.Content) > 1000 {
		return fmt.Errorf("comment content cannot exceed 1000 characters")
	}
	if c.UserID == "" {
		return fmt.Errorf("user ID is required")
	}
	if c.MediaItemID == "" {
		return fmt.Errorf("media item ID is required")
	}
	return nil
}

// IsReply checks if the comment is a reply to another comment
func (c *Comment) IsReply() bool {
	return c.ParentID != nil
}

// IsActive checks if the comment is active
func (c *Comment) IsActive() bool {
	return c.Status == CommentStatusActive
}

// IsDeleted checks if the comment is deleted
func (c *Comment) IsDeleted() bool {
	return c.Status == CommentStatusDeleted || c.DeletedAt != nil
}

// CanBeEdited checks if the comment can be edited
func (c *Comment) CanBeEdited() bool {
	return c.IsActive() && !c.IsDeleted()
}

// CanBeDeleted checks if the comment can be deleted
func (c *Comment) CanBeDeleted() bool {
	return c.IsActive() && !c.IsDeleted()
}

// SetEdited marks the comment as edited
func (c *Comment) SetEdited() {
	c.IsEdited = true
	c.UpdatedAt = time.Now()
}

// SoftDelete performs a soft delete on the comment
func (c *Comment) SoftDelete() {
	c.Status = CommentStatusDeleted
	now := time.Now()
	c.DeletedAt = &now
	c.UpdatedAt = now
}

// GenerateID generates a new UUID for the comment
func (c *Comment) GenerateID() {
	c.ID = uuid.New().String()
}

// SetTimestamps sets the created and updated timestamps
func (c *Comment) SetTimestamps() {
	now := time.Now()
	if c.CreatedAt.IsZero() {
		c.CreatedAt = now
	}
	c.UpdatedAt = now
}
