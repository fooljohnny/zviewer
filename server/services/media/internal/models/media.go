package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"
)

// MediaItem represents a media file in the system
type MediaItem struct {
	ID              string                 `json:"id" db:"id"`
	Title           string                 `json:"title" db:"title"`
	Description     string                 `json:"description" db:"description"`
	FilePath        string                 `json:"filePath" db:"file_path"`
	Type            MediaType              `json:"type" db:"type"`
	UserID          string                 `json:"userId" db:"user_id"`
	UserName        string                 `json:"userName" db:"user_name"`
	Status          MediaStatus            `json:"status" db:"status"`
	Categories      []string               `json:"categories" db:"categories"`
	UploadedAt      time.Time              `json:"uploadedAt" db:"uploaded_at"`
	ApprovedAt      *time.Time             `json:"approvedAt" db:"approved_at"`
	ApprovedBy      *string                `json:"approvedBy" db:"approved_by"`
	RejectionReason *string                `json:"rejectionReason" db:"rejection_reason"`
	Metadata        map[string]interface{} `json:"metadata" db:"metadata"`
	FileSize        int64                  `json:"fileSize" db:"file_size"`
	MimeType        string                 `json:"mimeType" db:"mime_type"`
	ThumbnailPath   *string                `json:"thumbnailPath" db:"thumbnail_path"`
}

// MediaType represents the type of media file
type MediaType string

const (
	MediaTypeImage MediaType = "image"
	MediaTypeVideo MediaType = "video"
)

// MediaStatus represents the approval status of a media item
type MediaStatus string

const (
	MediaStatusPending  MediaStatus = "pending"
	MediaStatusApproved MediaStatus = "approved"
	MediaStatusRejected MediaStatus = "rejected"
)

// MediaListResponse represents the response for listing media items
type MediaListResponse struct {
	Media []MediaItem `json:"media"`
	Total int64       `json:"total"`
	Page  int         `json:"page"`
	Limit int         `json:"limit"`
}

// MediaUploadRequest represents the request for uploading media
type MediaUploadRequest struct {
	Title       string   `json:"title" binding:"required"`
	Description string   `json:"description"`
	Categories  []string `json:"categories"`
}

// MediaUpdateRequest represents the request for updating media metadata
type MediaUpdateRequest struct {
	Title       string   `json:"title" binding:"required"`
	Description string   `json:"description"`
	Categories  []string `json:"categories"`
}

// MediaQuery represents query parameters for listing media
type MediaQuery struct {
	Page      int      `form:"page" binding:"min=1"`
	Limit     int      `form:"limit" binding:"min=1,max=100"`
	Type      string   `form:"type"`
	Status    string   `form:"status"`
	Search    string   `form:"search"`
	UserID    string   `form:"userId"`
	Categories []string `form:"categories"`
	SortBy    string   `form:"sortBy"`
	SortOrder string   `form:"sortOrder"`
}

// SetDefaults sets default values for the query
func (q *MediaQuery) SetDefaults() {
	if q.Page <= 0 {
		q.Page = 1
	}
	if q.Limit <= 0 {
		q.Limit = 20
	}
	if q.SortBy == "" {
		q.SortBy = "uploaded_at"
	}
	if q.SortOrder == "" {
		q.SortOrder = "desc"
	}
}

// MediaMetadata represents additional metadata for media files
type MediaMetadata struct {
	Width       int    `json:"width,omitempty"`
	Height      int    `json:"height,omitempty"`
	Duration    int    `json:"duration,omitempty"` // in seconds
	Format      string `json:"format,omitempty"`
	Codec       string `json:"codec,omitempty"`
	Bitrate     int    `json:"bitrate,omitempty"`
	Framerate   int    `json:"framerate,omitempty"`
	Orientation int    `json:"orientation,omitempty"`
	Camera      string `json:"camera,omitempty"`
	Location    string `json:"location,omitempty"`
}

// Value implements the driver.Valuer interface for database storage
func (m MediaMetadata) Value() (driver.Value, error) {
	return json.Marshal(m)
}

// Scan implements the sql.Scanner interface for database retrieval
func (m *MediaMetadata) Scan(value interface{}) error {
	if value == nil {
		return nil
	}
	
	bytes, ok := value.([]byte)
	if !ok {
		return nil
	}
	
	return json.Unmarshal(bytes, m)
}

// UploadProgress represents the progress of a file upload
type UploadProgress struct {
	UploadID    string    `json:"uploadId"`
	UserID      string    `json:"userId"`
	FileName    string    `json:"fileName"`
	FileSize    int64     `json:"fileSize"`
	UploadedSize int64    `json:"uploadedSize"`
	Progress    float64   `json:"progress"` // 0.0 to 1.0
	Status      string    `json:"status"`   // "uploading", "processing", "completed", "failed"
	Error       string    `json:"error,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// ChunkedUploadRequest represents a request for chunked file upload
type ChunkedUploadRequest struct {
	UploadID    string `json:"uploadId" binding:"required"`
	ChunkIndex  int    `json:"chunkIndex" binding:"required,min=0"`
	TotalChunks int    `json:"totalChunks" binding:"required,min=1"`
	ChunkSize   int64  `json:"chunkSize" binding:"required,min=1"`
	FileName    string `json:"fileName" binding:"required"`
	FileSize    int64  `json:"fileSize" binding:"required,min=1"`
	Title       string `json:"title" binding:"required"`
	Description string `json:"description"`
	Categories  []string `json:"categories"`
}

// ChunkedUploadResponse represents the response for chunked upload
type ChunkedUploadResponse struct {
	UploadID     string  `json:"uploadId"`
	ChunkIndex   int     `json:"chunkIndex"`
	Received     bool    `json:"received"`
	Progress     float64 `json:"progress"`
	IsComplete   bool    `json:"isComplete"`
	MediaID      string  `json:"mediaId,omitempty"`
	ErrorMessage string  `json:"errorMessage,omitempty"`
}