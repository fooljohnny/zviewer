package models

import (
	"time"

	"github.com/google/uuid"
)

// AlbumStatus represents the status of an album
type AlbumStatus string

const (
	AlbumStatusDraft     AlbumStatus = "draft"
	AlbumStatusPublished AlbumStatus = "published"
	AlbumStatusArchived  AlbumStatus = "archived"
)

// Album represents an album in the system
type Album struct {
	ID                string            `json:"id" db:"id"`
	Title             string            `json:"title" db:"title"`
	Description       string            `json:"description" db:"description"`
	CoverImageID      *string           `json:"coverImageId" db:"cover_image_id"`
	CoverImagePath    *string           `json:"coverImagePath" db:"cover_image_path"`
	CoverThumbnailPath *string          `json:"coverThumbnailPath" db:"cover_thumbnail_path"`
	Status            AlbumStatus       `json:"status" db:"status"`
	UserID            string            `json:"userId" db:"user_id"`
	CreatedAt         time.Time         `json:"createdAt" db:"created_at"`
	UpdatedAt         time.Time         `json:"updatedAt" db:"updated_at"`
	Metadata          map[string]interface{} `json:"metadata" db:"metadata"`
	IsPublic          bool              `json:"isPublic" db:"is_public"`
	ViewCount         int               `json:"viewCount" db:"view_count"`
	LikeCount         int               `json:"likeCount" db:"like_count"`
	Tags              []string          `json:"tags" db:"tags"`
	ImageCount        int               `json:"imageCount" db:"-"` // Computed field
	Images            []AlbumImage      `json:"images" db:"-"`     // Related images
}

// AlbumImage represents an image in an album
type AlbumImage struct {
	ID           string    `json:"id" db:"id"`
	AlbumID      string    `json:"albumId" db:"album_id"`
	ImageID      string    `json:"imageId" db:"image_id"`
	ImagePath    string    `json:"imagePath" db:"image_path"`
	ThumbnailPath *string  `json:"thumbnailPath" db:"thumbnail_path"`
	MimeType     *string   `json:"mimeType" db:"mime_type"`
	FileSize     *int64    `json:"fileSize" db:"file_size"`
	Width        *int      `json:"width" db:"width"`
	Height       *int      `json:"height" db:"height"`
	SortOrder    int       `json:"sortOrder" db:"sort_order"`
	AddedAt      time.Time `json:"addedAt" db:"added_at"`
	AddedBy      string    `json:"addedBy" db:"added_by"`
}

// CreateAlbumRequest represents the request for creating an album
type CreateAlbumRequest struct {
	Title       string   `json:"title" binding:"required,min=1,max=255"`
	Description string   `json:"description" binding:"max=2000"`
	ImageIDs    []string `json:"imageIds" binding:"required,min=1"`
	Tags        []string `json:"tags"`
	IsPublic    bool     `json:"isPublic"`
}

// UpdateAlbumRequest represents the request for updating an album
type UpdateAlbumRequest struct {
	Title       *string      `json:"title" binding:"omitempty,min=1,max=255"`
	Description *string      `json:"description" binding:"omitempty,max=2000"`
	ImageIDs    []string     `json:"imageIds"`
	CoverImageID *string     `json:"coverImageId"`
	Tags        []string     `json:"tags"`
	IsPublic    *bool        `json:"isPublic"`
	Status      *AlbumStatus `json:"status" binding:"omitempty,oneof=draft published archived"`
}

// AlbumListResponse represents the response for album list endpoints
type AlbumListResponse struct {
	Albums     []Album `json:"albums"`
	Total      int     `json:"total"`
	Page       int     `json:"page"`
	Limit      int     `json:"limit"`
	TotalPages int     `json:"totalPages"`
}

// AlbumActionResponse represents the response for album action endpoints
type AlbumActionResponse struct {
	Success bool    `json:"success"`
	Message string  `json:"message"`
	Album   *Album  `json:"album,omitempty"`
}

// AddImageToAlbumRequest represents the request for adding images to an album
type AddImageToAlbumRequest struct {
	ImageIDs []string `json:"imageIds" binding:"required,min=1"`
}

// RemoveImageFromAlbumRequest represents the request for removing images from an album
type RemoveImageFromAlbumRequest struct {
	ImageIDs []string `json:"imageIds" binding:"required,min=1"`
}

// SetAlbumCoverRequest represents the request for setting album cover
type SetAlbumCoverRequest struct {
	ImageID string `json:"imageId" binding:"required"`
}

// NewAlbum creates a new album with generated ID
func NewAlbum(title, description, userID string, imageIDs []string, tags []string, isPublic bool) *Album {
	now := time.Now()
	return &Album{
		ID:         uuid.New().String(),
		Title:      title,
		Description: description,
		Status:     AlbumStatusDraft,
		UserID:     userID,
		CreatedAt:  now,
		UpdatedAt:  now,
		Metadata:   make(map[string]interface{}),
		IsPublic:   isPublic,
		ViewCount:  0,
		LikeCount:  0,
		Tags:       tags,
		ImageCount: len(imageIDs),
	}
}

// IsDraft returns true if the album is in draft status
func (a *Album) IsDraft() bool {
	return a.Status == AlbumStatusDraft
}

// IsPublished returns true if the album is published
func (a *Album) IsPublished() bool {
	return a.Status == AlbumStatusPublished
}

// IsArchived returns true if the album is archived
func (a *Album) IsArchived() bool {
	return a.Status == AlbumStatusArchived
}

// HasCover returns true if the album has a cover image
func (a *Album) HasCover() bool {
	return a.CoverImageID != nil && *a.CoverImageID != ""
}

// IsEmpty returns true if the album has no images
func (a *Album) IsEmpty() bool {
	return a.ImageCount == 0
}

// IsNotEmpty returns true if the album has images
func (a *Album) IsNotEmpty() bool {
	return a.ImageCount > 0
}

// IsValid returns true if the album has valid data
func (a *Album) IsValid() bool {
	return a.ID != "" && 
		   a.Title != "" && 
		   a.UserID != "" &&
		   len(a.Title) <= 255 &&
		   len(a.Description) <= 2000
}

// UpdateCover sets the cover image for the album
func (a *Album) UpdateCover(imageID, imagePath, thumbnailPath string) {
	a.CoverImageID = &imageID
	a.CoverImagePath = &imagePath
	a.CoverThumbnailPath = &thumbnailPath
	a.UpdatedAt = time.Now()
}

// IncrementViewCount increments the view count
func (a *Album) IncrementViewCount() {
	a.ViewCount++
	a.UpdatedAt = time.Now()
}

// IncrementLikeCount increments the like count
func (a *Album) IncrementLikeCount() {
	a.LikeCount++
	a.UpdatedAt = time.Now()
}

// DecrementLikeCount decrements the like count
func (a *Album) DecrementLikeCount() {
	if a.LikeCount > 0 {
		a.LikeCount--
		a.UpdatedAt = time.Now()
	}
}

// ToPublicAlbum returns an album without sensitive information
func (a *Album) ToPublicAlbum() *Album {
	return &Album{
		ID:                a.ID,
		Title:             a.Title,
		Description:       a.Description,
		CoverImageID:      a.CoverImageID,
		CoverImagePath:    a.CoverImagePath,
		CoverThumbnailPath: a.CoverThumbnailPath,
		Status:            a.Status,
		UserID:            a.UserID,
		CreatedAt:         a.CreatedAt,
		UpdatedAt:         a.UpdatedAt,
		Metadata:          a.Metadata,
		IsPublic:          a.IsPublic,
		ViewCount:         a.ViewCount,
		LikeCount:         a.LikeCount,
		Tags:              a.Tags,
		ImageCount:        a.ImageCount,
		Images:            a.Images,
	}
}

// NewAlbumImage creates a new album image
func NewAlbumImage(albumID, imageID, imagePath, addedBy string, sortOrder int) *AlbumImage {
	now := time.Now()
	return &AlbumImage{
		ID:        uuid.New().String(),
		AlbumID:   albumID,
		ImageID:   imageID,
		ImagePath: imagePath,
		SortOrder: sortOrder,
		AddedAt:   now,
		AddedBy:   addedBy,
	}
}
