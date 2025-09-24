package repositories

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"zviewer-media-service/internal/models"
)

// MediaRepository handles database operations for media items
type MediaRepository struct {
	db *sql.DB
}

// NewMediaRepository creates a new media repository
func NewMediaRepository(db *sql.DB) *MediaRepository {
	return &MediaRepository{db: db}
}

// Create creates a new media item
func (r *MediaRepository) Create(media *models.MediaItem) error {
	query := `
		INSERT INTO media_items (
			id, title, description, file_path, type, user_id, user_name, 
			status, categories, uploaded_at, metadata, file_size, mime_type, thumbnail_path
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
	`

	metadataJSON, _ := json.Marshal(media.Metadata)

	_, err := r.db.Exec(query,
		media.ID, media.Title, media.Description, media.FilePath, media.Type,
		media.UserID, media.UserName, media.Status, media.Categories,
		media.UploadedAt, metadataJSON, media.FileSize, media.MimeType, media.ThumbnailPath,
	)

	return err
}

// GetByID retrieves a media item by ID
func (r *MediaRepository) GetByID(id string) (*models.MediaItem, error) {
	query := `
		SELECT id, title, description, file_path, type, user_id, user_name,
		       status, categories, uploaded_at, approved_at, approved_by,
		       rejection_reason, metadata, file_size, mime_type, thumbnail_path
		FROM media_items WHERE id = $1
	`

	var media models.MediaItem
	var metadataJSON []byte

	err := r.db.QueryRow(query, id).Scan(
		&media.ID, &media.Title, &media.Description, &media.FilePath, &media.Type,
		&media.UserID, &media.UserName, &media.Status, &media.Categories,
		&media.UploadedAt, &media.ApprovedAt, &media.ApprovedBy,
		&media.RejectionReason, &metadataJSON, &media.FileSize, &media.MimeType, &media.ThumbnailPath,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("media item not found")
		}
		return nil, err
	}

	// Parse metadata JSON
	if len(metadataJSON) > 0 {
		json.Unmarshal(metadataJSON, &media.Metadata)
	}

	return &media, nil
}

// Update updates a media item
func (r *MediaRepository) Update(media *models.MediaItem) error {
	query := `
		UPDATE media_items SET
			title = $2, description = $3, categories = $4, metadata = $5, thumbnail_path = $6
		WHERE id = $1
	`

	metadataJSON, _ := json.Marshal(media.Metadata)

	_, err := r.db.Exec(query,
		media.ID, media.Title, media.Description, media.Categories,
		metadataJSON, media.ThumbnailPath,
	)

	return err
}

// Delete deletes a media item
func (r *MediaRepository) Delete(id string) error {
	query := `DELETE FROM media_items WHERE id = $1`
	_, err := r.db.Exec(query, id)
	return err
}

// List retrieves media items with pagination and filtering
func (r *MediaRepository) List(query models.MediaQuery) ([]models.MediaItem, int64, error) {
	// Build WHERE clause
	whereClause, args := r.buildWhereClause(query)

	// Build ORDER BY clause
	orderClause := r.buildOrderClause(query)

	// Count total records
	countQuery := `SELECT COUNT(*) FROM media_items ` + whereClause
	var total int64
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Build main query
	offset := (query.Page - 1) * query.Limit
	mainQuery := `
		SELECT id, title, description, file_path, type, user_id, user_name,
		       status, categories, uploaded_at, approved_at, approved_by,
		       rejection_reason, metadata, file_size, mime_type, thumbnail_path
		FROM media_items ` + whereClause + orderClause + ` LIMIT $` + fmt.Sprintf("%d", len(args)+1) + ` OFFSET $` + fmt.Sprintf("%d", len(args)+2)

	args = append(args, query.Limit, offset)

	rows, err := r.db.Query(mainQuery, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var mediaItems []models.MediaItem
	for rows.Next() {
		var media models.MediaItem
		var metadataJSON []byte

		err := rows.Scan(
			&media.ID, &media.Title, &media.Description, &media.FilePath, &media.Type,
			&media.UserID, &media.UserName, &media.Status, &media.Categories,
			&media.UploadedAt, &media.ApprovedAt, &media.ApprovedBy,
			&media.RejectionReason, &metadataJSON, &media.FileSize, &media.MimeType, &media.ThumbnailPath,
		)
		if err != nil {
			return nil, 0, err
		}

		// Parse metadata JSON
		if len(metadataJSON) > 0 {
			json.Unmarshal(metadataJSON, &media.Metadata)
		}

		mediaItems = append(mediaItems, media)
	}

	return mediaItems, total, nil
}

// UpdateStatus updates the status of a media item
func (r *MediaRepository) UpdateStatus(id string, status models.MediaStatus, approvedBy *string, rejectionReason *string) error {
	query := `
		UPDATE media_items SET
			status = $2, approved_at = $3, approved_by = $4, rejection_reason = $5
		WHERE id = $1
	`

	var approvedAt *time.Time
	if status == models.MediaStatusApproved {
		now := time.Now()
		approvedAt = &now
	}

	_, err := r.db.Exec(query, id, status, approvedAt, approvedBy, rejectionReason)
	return err
}

// buildWhereClause builds the WHERE clause for queries
func (r *MediaRepository) buildWhereClause(query models.MediaQuery) (string, []interface{}) {
	var conditions []string
	var args []interface{}
	argIndex := 1

	if query.Type != "" {
		conditions = append(conditions, fmt.Sprintf("type = $%d", argIndex))
		args = append(args, query.Type)
		argIndex++
	}

	if query.Status != "" {
		conditions = append(conditions, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, query.Status)
		argIndex++
	}

	if query.UserID != "" {
		conditions = append(conditions, fmt.Sprintf("user_id = $%d", argIndex))
		args = append(args, query.UserID)
		argIndex++
	}

	if query.Search != "" {
		conditions = append(conditions, fmt.Sprintf("to_tsvector('english', title || ' ' || COALESCE(description, '')) @@ plainto_tsquery('english', $%d)", argIndex))
		args = append(args, query.Search)
		argIndex++
	}

	if len(query.Categories) > 0 {
		conditions = append(conditions, fmt.Sprintf("categories && $%d", argIndex))
		args = append(args, query.Categories)
		argIndex++
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	return whereClause, args
}

// buildOrderClause builds the ORDER BY clause for queries
func (r *MediaRepository) buildOrderClause(query models.MediaQuery) string {
	orderBy := query.SortBy
	if orderBy == "" {
		orderBy = "uploaded_at"
	}

	// Validate sort column
	validColumns := map[string]bool{
		"uploaded_at": true,
		"title":       true,
		"file_size":   true,
		"status":      true,
	}

	if !validColumns[orderBy] {
		orderBy = "uploaded_at"
	}

	order := query.SortOrder
	if order != "asc" && order != "desc" {
		order = "desc"
	}

	return fmt.Sprintf(" ORDER BY %s %s", orderBy, strings.ToUpper(order))
}
