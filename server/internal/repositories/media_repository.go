package repositories

import (
	"database/sql"
	"encoding/json"
	"fmt"

	"zviewer-server/internal/models"

	"github.com/sirupsen/logrus"
)

// MediaRepository handles media database operations
type MediaRepository struct {
	db     *sql.DB
	logger *logrus.Logger
}

// NewMediaRepository creates a new media repository
func NewMediaRepository(db *sql.DB, logger *logrus.Logger) *MediaRepository {
	return &MediaRepository{
		db:     db,
		logger: logger,
	}
}

// GetByID retrieves a media item by ID
func (r *MediaRepository) GetByID(id string) (*models.MediaItem, error) {
	query := `
		SELECT id, title, description, file_path, type, user_id, user_name, 
		       status, categories, uploaded_at, approved_at, approved_by, 
		       rejection_reason, metadata, file_size, mime_type, thumbnail_path
		FROM media_items 
		WHERE id = $1
	`

	var media models.MediaItem
	var categoriesJSON, metadataJSON []byte

	err := r.db.QueryRow(query, id).Scan(
		&media.ID, &media.Title, &media.Description, &media.FilePath, &media.Type,
		&media.UserID, &media.UserName, &media.Status, &categoriesJSON,
		&media.UploadedAt, &media.ApprovedAt, &media.ApprovedBy,
		&media.RejectionReason, &metadataJSON, &media.FileSize, &media.MimeType, &media.ThumbnailPath,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("media not found")
		}
		return nil, fmt.Errorf("failed to get media: %w", err)
	}

	// Parse JSON fields
	if len(categoriesJSON) > 0 {
		if err := json.Unmarshal(categoriesJSON, &media.Categories); err != nil {
			r.logger.Warnf("Failed to parse categories for media %s: %v", id, err)
			media.Categories = []string{}
		}
	}

	if len(metadataJSON) > 0 {
		if err := json.Unmarshal(metadataJSON, &media.Metadata); err != nil {
			r.logger.Warnf("Failed to parse metadata for media %s: %v", id, err)
			media.Metadata = make(map[string]interface{})
		}
	}

	return &media, nil
}
