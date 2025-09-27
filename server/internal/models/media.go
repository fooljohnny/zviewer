package models

import (
	"time"
)

// MediaItem represents a media item in the database
type MediaItem struct {
	ID              string                 `json:"id" db:"id"`
	Title           string                 `json:"title" db:"title"`
	Description     string                 `json:"description" db:"description"`
	FilePath        string                 `json:"file_path" db:"file_path"`
	Type            string                 `json:"type" db:"type"`
	UserID          string                 `json:"user_id" db:"user_id"`
	UserName        string                 `json:"user_name" db:"user_name"`
	Status          string                 `json:"status" db:"status"`
	Categories      []string               `json:"categories" db:"categories"`
	UploadedAt      time.Time              `json:"uploaded_at" db:"uploaded_at"`
	ApprovedAt      *time.Time             `json:"approved_at" db:"approved_at"`
	ApprovedBy      *string                `json:"approved_by" db:"approved_by"`
	RejectionReason *string                `json:"rejection_reason" db:"rejection_reason"`
	Metadata        map[string]interface{} `json:"metadata" db:"metadata"`
	FileSize        int64                  `json:"file_size" db:"file_size"`
	MimeType        string                 `json:"mime_type" db:"mime_type"`
	ThumbnailPath   *string                `json:"thumbnail_path" db:"thumbnail_path"`
}
