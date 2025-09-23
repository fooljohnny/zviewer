package repositories

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"zviewer-comments-service/internal/models"
)

// CommentRepository handles database operations for comments
type CommentRepository struct {
	db *sql.DB
}

// NewCommentRepository creates a new comment repository
func NewCommentRepository(db *sql.DB) *CommentRepository {
	return &CommentRepository{db: db}
}

// Create creates a new comment
func (r *CommentRepository) Create(comment *models.Comment) error {
	query := `
		INSERT INTO comments (id, user_id, media_item_id, parent_id, content, status, created_at, updated_at, is_edited)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`

	_, err := r.db.Exec(query,
		comment.ID,
		comment.UserID,
		comment.MediaItemID,
		comment.ParentID,
		comment.Content,
		comment.Status,
		comment.CreatedAt,
		comment.UpdatedAt,
		comment.IsEdited,
	)

	if err != nil {
		return fmt.Errorf("failed to create comment: %w", err)
	}

	return nil
}

// GetByID retrieves a comment by ID
func (r *CommentRepository) GetByID(id string) (*models.Comment, error) {
	query := `
		SELECT c.id, c.user_id, c.media_item_id, c.parent_id, c.content, c.status, 
		       c.created_at, c.updated_at, c.deleted_at, c.is_edited, c.replies_count,
		       u.username as user_name
		FROM comments c
		LEFT JOIN users u ON c.user_id = u.id
		WHERE c.id = $1
	`

	comment := &models.Comment{}
	err := r.db.QueryRow(query, id).Scan(
		&comment.ID, &comment.UserID, &comment.MediaItemID, &comment.ParentID,
		&comment.Content, &comment.Status, &comment.CreatedAt, &comment.UpdatedAt,
		&comment.DeletedAt, &comment.IsEdited, &comment.RepliesCount, &comment.UserName,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("comment not found")
		}
		return nil, fmt.Errorf("failed to get comment: %w", err)
	}

	return comment, nil
}

// Update updates a comment
func (r *CommentRepository) Update(comment *models.Comment) error {
	query := `
		UPDATE comments 
		SET content = $2, status = $3, updated_at = $4, is_edited = $5
		WHERE id = $1
	`

	_, err := r.db.Exec(query,
		comment.ID,
		comment.Content,
		comment.Status,
		comment.UpdatedAt,
		comment.IsEdited,
	)

	if err != nil {
		return fmt.Errorf("failed to update comment: %w", err)
	}

	return nil
}

// Delete soft deletes a comment
func (r *CommentRepository) Delete(id string) error {
	query := `
		UPDATE comments 
		SET status = 'deleted', deleted_at = $2, updated_at = $2
		WHERE id = $1
	`

	_, err := r.db.Exec(query, id, time.Now())
	if err != nil {
		return fmt.Errorf("failed to delete comment: %w", err)
	}

	return nil
}

// List retrieves comments with pagination and filtering
func (r *CommentRepository) List(query models.CommentQuery) ([]models.Comment, int64, error) {
	query.SetDefaults()

	// Build WHERE clause
	whereClause, args := r.buildWhereClause(query)

	// Count total records
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM comments c LEFT JOIN users u ON c.user_id = u.id %s", whereClause)
	var total int64
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count comments: %w", err)
	}

	// Build main query
	mainQuery := fmt.Sprintf(`
		SELECT c.id, c.user_id, c.media_item_id, c.parent_id, c.content, c.status,
		       c.created_at, c.updated_at, c.deleted_at, c.is_edited, c.replies_count,
		       u.username as user_name
		FROM comments c
		LEFT JOIN users u ON c.user_id = u.id
		%s
		ORDER BY c.%s %s
		LIMIT $%d OFFSET $%d
	`, whereClause, query.SortBy, query.SortOrder, len(args)+1, len(args)+2)

	// Add pagination parameters
	args = append(args, query.Limit, (query.Page-1)*query.Limit)

	rows, err := r.db.Query(mainQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to query comments: %w", err)
	}
	defer rows.Close()

	var comments []models.Comment
	for rows.Next() {
		comment := models.Comment{}
		err := rows.Scan(
			&comment.ID, &comment.UserID, &comment.MediaItemID, &comment.ParentID,
			&comment.Content, &comment.Status, &comment.CreatedAt, &comment.UpdatedAt,
			&comment.DeletedAt, &comment.IsEdited, &comment.RepliesCount, &comment.UserName,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan comment: %w", err)
		}
		comments = append(comments, comment)
	}

	return comments, total, nil
}

// GetByMediaID retrieves comments for a specific media item
func (r *CommentRepository) GetByMediaID(mediaID string, query models.CommentQuery) ([]models.Comment, int64, error) {
	query.MediaID = mediaID
	return r.List(query)
}

// GetReplies retrieves replies to a specific comment
func (r *CommentRepository) GetReplies(parentID string, query models.CommentQuery) ([]models.Comment, int64, error) {
	query.ParentID = parentID
	return r.List(query)
}

// GetStats retrieves comment statistics
func (r *CommentRepository) GetStats() (*models.CommentStats, error) {
	query := `
		SELECT total_comments, active_comments, deleted_comments, moderated_comments,
		       pending_comments, comments_today, comments_this_week, comments_this_month
		FROM comment_stats
	`

	stats := &models.CommentStats{}
	err := r.db.QueryRow(query).Scan(
		&stats.TotalComments, &stats.ActiveComments, &stats.DeletedComments,
		&stats.ModeratedComments, &stats.PendingComments, &stats.CommentsToday,
		&stats.CommentsThisWeek, &stats.CommentsThisMonth,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get comment stats: %w", err)
	}

	return stats, nil
}

// GetUserStats retrieves user comment statistics
func (r *CommentRepository) GetUserStats(userID string) (*models.UserCommentStats, error) {
	query := `
		SELECT user_id, user_name, total_comments, active_comments, last_comment_at
		FROM user_comment_stats
		WHERE user_id = $1
	`

	stats := &models.UserCommentStats{}
	err := r.db.QueryRow(query, userID).Scan(
		&stats.UserID, &stats.UserName, &stats.TotalComments,
		&stats.ActiveComments, &stats.LastCommentAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return &models.UserCommentStats{UserID: userID}, nil
		}
		return nil, fmt.Errorf("failed to get user stats: %w", err)
	}

	return stats, nil
}

// GetMediaStats retrieves media comment statistics
func (r *CommentRepository) GetMediaStats(mediaID string) (*models.MediaCommentStats, error) {
	query := `
		SELECT media_item_id, total_comments, active_comments, last_comment_at
		FROM media_comment_stats
		WHERE media_item_id = $1
	`

	stats := &models.MediaCommentStats{}
	err := r.db.QueryRow(query, mediaID).Scan(
		&stats.MediaID, &stats.TotalComments, &stats.ActiveComments, &stats.LastCommentAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return &models.MediaCommentStats{MediaID: mediaID}, nil
		}
		return nil, fmt.Errorf("failed to get media stats: %w", err)
	}

	return stats, nil
}

// buildWhereClause builds the WHERE clause for queries
func (r *CommentRepository) buildWhereClause(query models.CommentQuery) (string, []interface{}) {
	var conditions []string
	var args []interface{}
	argIndex := 1

	if query.MediaID != "" {
		conditions = append(conditions, fmt.Sprintf("c.media_item_id = $%d", argIndex))
		args = append(args, query.MediaID)
		argIndex++
	}

	if query.UserID != "" {
		conditions = append(conditions, fmt.Sprintf("c.user_id = $%d", argIndex))
		args = append(args, query.UserID)
		argIndex++
	}

	if query.Status != "" {
		conditions = append(conditions, fmt.Sprintf("c.status = $%d", argIndex))
		args = append(args, query.Status)
		argIndex++
	}

	if query.ParentID != "" {
		conditions = append(conditions, fmt.Sprintf("c.parent_id = $%d", argIndex))
		args = append(args, query.ParentID)
		argIndex++
	} else if query.ParentID == "null" {
		conditions = append(conditions, "c.parent_id IS NULL")
	}

	// Always exclude soft-deleted comments unless specifically requested
	if query.Status != "deleted" {
		conditions = append(conditions, "c.deleted_at IS NULL")
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	return whereClause, args
}

// ValidateMediaExists checks if a media item exists
func (r *CommentRepository) ValidateMediaExists(mediaID string) error {
	query := "SELECT id FROM media_items WHERE id = $1"
	var id string
	err := r.db.QueryRow(query, mediaID).Scan(&id)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("media item not found")
		}
		return fmt.Errorf("failed to validate media item: %w", err)
	}
	return nil
}

// ValidateUserExists checks if a user exists
func (r *CommentRepository) ValidateUserExists(userID string) error {
	query := "SELECT id FROM users WHERE id = $1"
	var id string
	err := r.db.QueryRow(query, userID).Scan(&id)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("user not found")
		}
		return fmt.Errorf("failed to validate user: %w", err)
	}
	return nil
}

// ValidateParentComment checks if a parent comment exists and is active
func (r *CommentRepository) ValidateParentComment(parentID string) error {
	query := "SELECT id, status FROM comments WHERE id = $1 AND deleted_at IS NULL"
	var id, status string
	err := r.db.QueryRow(query, parentID).Scan(&id, &status)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("parent comment not found")
		}
		return fmt.Errorf("failed to validate parent comment: %w", err)
	}
	if status != "active" {
		return fmt.Errorf("parent comment is not active")
	}
	return nil
}
