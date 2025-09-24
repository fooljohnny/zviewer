package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"zviewer-admin-service/internal/models"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

// ContentModerationRepository handles content moderation data operations
type ContentModerationRepository struct {
	db *sql.DB
}

// NewContentModerationRepository creates a new content moderation repository
func NewContentModerationRepository(db *sql.DB) *ContentModerationRepository {
	return &ContentModerationRepository{db: db}
}

// Create creates a new content moderation record
func (r *ContentModerationRepository) Create(moderation *models.ContentModeration) error {
	query := `
		INSERT INTO content_moderations (id, content_id, moderator_id, status, reason, flags, review_notes, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`

	_, err := r.db.Exec(query,
		moderation.ID,
		moderation.ContentID,
		moderation.ModeratorID,
		moderation.Status,
		moderation.Reason,
		moderation.Flags,
		moderation.ReviewNotes,
		moderation.CreatedAt,
		moderation.UpdatedAt,
	)

	if err != nil {
		logrus.WithError(err).Error("Failed to create content moderation")
		return fmt.Errorf("failed to create content moderation: %w", err)
	}

	return nil
}

// GetByID retrieves a content moderation record by ID
func (r *ContentModerationRepository) GetByID(id uuid.UUID) (*models.ContentModeration, error) {
	query := `
		SELECT id, content_id, moderator_id, status, reason, flags, review_notes, created_at, updated_at
		FROM content_moderations
		WHERE id = $1
	`

	moderation := &models.ContentModeration{}
	err := r.db.QueryRow(query, id).Scan(
		&moderation.ID,
		&moderation.ContentID,
		&moderation.ModeratorID,
		&moderation.Status,
		&moderation.Reason,
		&moderation.Flags,
		&moderation.ReviewNotes,
		&moderation.CreatedAt,
		&moderation.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("content moderation not found")
		}
		logrus.WithError(err).Error("Failed to get content moderation by ID")
		return nil, fmt.Errorf("failed to get content moderation: %w", err)
	}

	return moderation, nil
}

// GetByContentID retrieves content moderation by content ID
func (r *ContentModerationRepository) GetByContentID(contentID uuid.UUID) (*models.ContentModeration, error) {
	query := `
		SELECT id, content_id, moderator_id, status, reason, flags, review_notes, created_at, updated_at
		FROM content_moderations
		WHERE content_id = $1
	`

	moderation := &models.ContentModeration{}
	err := r.db.QueryRow(query, contentID).Scan(
		&moderation.ID,
		&moderation.ContentID,
		&moderation.ModeratorID,
		&moderation.Status,
		&moderation.Reason,
		&moderation.Flags,
		&moderation.ReviewNotes,
		&moderation.CreatedAt,
		&moderation.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("content moderation not found")
		}
		logrus.WithError(err).Error("Failed to get content moderation by content ID")
		return nil, fmt.Errorf("failed to get content moderation: %w", err)
	}

	return moderation, nil
}

// Update updates a content moderation record
func (r *ContentModerationRepository) Update(moderation *models.ContentModeration) error {
	query := `
		UPDATE content_moderations
		SET moderator_id = $2, status = $3, reason = $4, flags = $5, review_notes = $6, updated_at = $7
		WHERE id = $1
	`

	result, err := r.db.Exec(query,
		moderation.ID,
		moderation.ModeratorID,
		moderation.Status,
		moderation.Reason,
		moderation.Flags,
		moderation.ReviewNotes,
		moderation.UpdatedAt,
	)

	if err != nil {
		logrus.WithError(err).Error("Failed to update content moderation")
		return fmt.Errorf("failed to update content moderation: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("content moderation not found")
	}

	return nil
}

// List retrieves content moderations with pagination and filtering
func (r *ContentModerationRepository) List(offset, limit int, filters map[string]interface{}) ([]*models.ContentModeration, int, error) {
	// Build WHERE clause
	whereClause := "WHERE 1=1"
	args := []interface{}{}
	argIndex := 1

	if status, ok := filters["status"].(string); ok {
		whereClause += fmt.Sprintf(" AND status = $%d", argIndex)
		args = append(args, status)
		argIndex++
	}

	if moderatorID, ok := filters["moderator_id"].(uuid.UUID); ok {
		whereClause += fmt.Sprintf(" AND moderator_id = $%d", argIndex)
		args = append(args, moderatorID)
		argIndex++
	}

	if startDate, ok := filters["start_date"].(time.Time); ok {
		whereClause += fmt.Sprintf(" AND created_at >= $%d", argIndex)
		args = append(args, startDate)
		argIndex++
	}

	if endDate, ok := filters["end_date"].(time.Time); ok {
		whereClause += fmt.Sprintf(" AND created_at <= $%d", argIndex)
		args = append(args, endDate)
		argIndex++
	}

	// Count total records
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM content_moderations %s", whereClause)
	var total int
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		logrus.WithError(err).Error("Failed to count content moderations")
		return nil, 0, fmt.Errorf("failed to count content moderations: %w", err)
	}

	// Get paginated results
	query := fmt.Sprintf(`
		SELECT id, content_id, moderator_id, status, reason, flags, review_notes, created_at, updated_at
		FROM content_moderations
		%s
		ORDER BY created_at DESC
		OFFSET $%d LIMIT $%d
	`, whereClause, argIndex, argIndex+1)

	args = append(args, offset, limit)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		logrus.WithError(err).Error("Failed to list content moderations")
		return nil, 0, fmt.Errorf("failed to list content moderations: %w", err)
	}
	defer rows.Close()

	var moderations []*models.ContentModeration
	for rows.Next() {
		moderation := &models.ContentModeration{}
		err := rows.Scan(
			&moderation.ID,
			&moderation.ContentID,
			&moderation.ModeratorID,
			&moderation.Status,
			&moderation.Reason,
			&moderation.Flags,
			&moderation.ReviewNotes,
			&moderation.CreatedAt,
			&moderation.UpdatedAt,
		)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan content moderation")
			return nil, 0, fmt.Errorf("failed to scan content moderation: %w", err)
		}
		moderations = append(moderations, moderation)
	}

	return moderations, total, nil
}

// GetModerationQueue retrieves content pending moderation
func (r *ContentModerationRepository) GetModerationQueue(offset, limit int) ([]*models.ContentModeration, int, error) {
	whereClause := "WHERE status = 'pending'"

	// Count total records
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM content_moderations %s", whereClause)
	var total int
	err := r.db.QueryRow(countQuery).Scan(&total)
	if err != nil {
		logrus.WithError(err).Error("Failed to count pending moderations")
		return nil, 0, fmt.Errorf("failed to count pending moderations: %w", err)
	}

	// Get paginated results
	query := fmt.Sprintf(`
		SELECT id, content_id, moderator_id, status, reason, flags, review_notes, created_at, updated_at
		FROM content_moderations
		%s
		ORDER BY created_at ASC
		OFFSET $1 LIMIT $2
	`, whereClause)

	rows, err := r.db.Query(query, offset, limit)
	if err != nil {
		logrus.WithError(err).Error("Failed to get moderation queue")
		return nil, 0, fmt.Errorf("failed to get moderation queue: %w", err)
	}
	defer rows.Close()

	var moderations []*models.ContentModeration
	for rows.Next() {
		moderation := &models.ContentModeration{}
		err := rows.Scan(
			&moderation.ID,
			&moderation.ContentID,
			&moderation.ModeratorID,
			&moderation.Status,
			&moderation.Reason,
			&moderation.Flags,
			&moderation.ReviewNotes,
			&moderation.CreatedAt,
			&moderation.UpdatedAt,
		)
		if err != nil {
			logrus.WithError(err).Error("Failed to scan content moderation")
			return nil, 0, fmt.Errorf("failed to scan content moderation: %w", err)
		}
		moderations = append(moderations, moderation)
	}

	return moderations, total, nil
}

// Delete deletes a content moderation record
func (r *ContentModerationRepository) Delete(id uuid.UUID) error {
	query := "DELETE FROM content_moderations WHERE id = $1"

	result, err := r.db.Exec(query, id)
	if err != nil {
		logrus.WithError(err).Error("Failed to delete content moderation")
		return fmt.Errorf("failed to delete content moderation: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("content moderation not found")
	}

	return nil
}
