package services

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"zviewer-media-service/internal/config"
	"zviewer-media-service/internal/models"
	"zviewer-media-service/internal/processing"
	"zviewer-media-service/internal/repositories"
	"zviewer-media-service/internal/storage"

	"github.com/sirupsen/logrus"
)

// MediaService handles business logic for media operations
type MediaService struct {
	mediaRepo      *repositories.MediaRepository
	storage        storage.Storage
	pathGenerator  *storage.PathGenerator
	imageProcessor *processing.ImageProcessor
	videoProcessor *processing.VideoProcessor
	config         *config.Config
}

// NewMediaService creates a new media service
func NewMediaService(mediaRepo *repositories.MediaRepository, cfg *config.Config) *MediaService {
	// Create storage factory and get storage instance
	storageFactory := storage.NewStorageFactory()
	storageInstance, err := storageFactory.CreateStorage(cfg)
	if err != nil {
		logrus.Fatalf("Failed to create storage: %v", err)
	}

	return &MediaService{
		mediaRepo:      mediaRepo,
		storage:        storageInstance,
		pathGenerator:  storage.NewPathGenerator(),
		imageProcessor: processing.NewImageProcessor(cfg.ImageThumbnailSize),
		videoProcessor: processing.NewVideoProcessor(cfg.VideoThumbnailSize, cfg.VideoThumbnailTime),
		config:         cfg,
	}
}

// UploadMedia handles file upload and processing
func (s *MediaService) UploadMedia(ctx context.Context, file *multipart.FileHeader, req models.MediaUploadRequest, userID, userName string) (*models.MediaItem, error) {
	// Validate file
	if err := s.validateFile(file); err != nil {
		return nil, fmt.Errorf("file validation failed: %w", err)
	}

	// Generate file path
	filePath, fileID, err := s.pathGenerator.GeneratePath(userID, file.Filename)
	if err != nil {
		return nil, fmt.Errorf("failed to generate file path: %w", err)
	}

	// Open file
	src, err := file.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open uploaded file: %w", err)
	}
	defer src.Close()

	// Save file to storage
	if err := s.storage.SaveFile(ctx, filePath, src); err != nil {
		return nil, fmt.Errorf("failed to save file: %w", err)
	}

	// Determine media type
	mediaType := s.determineMediaType(file.Filename, file.Header.Get("Content-Type"))

	// Create media item
	media := &models.MediaItem{
		ID:          fileID,
		Title:       req.Title,
		Description: req.Description,
		FilePath:    filePath,
		Type:        mediaType,
		UserID:      userID,
		UserName:    userName,
		Status:      models.MediaStatusPending,
		Categories:  req.Categories,
		UploadedAt:  time.Now(),
		FileSize:    file.Size,
		MimeType:    file.Header.Get("Content-Type"),
		Metadata:    make(map[string]interface{}),
	}

	// Save to database
	if err := s.mediaRepo.Create(media); err != nil {
		// Clean up stored file if database save fails
		s.storage.DeleteFile(ctx, filePath)
		return nil, fmt.Errorf("failed to save media to database: %w", err)
	}

	// Process file in background (thumbnail generation, etc.)
	go s.processFileAsync(context.Background(), media)

	return media, nil
}

// SaveMedia saves a media item to the database
func (s *MediaService) SaveMedia(ctx context.Context, media *models.MediaItem) error {
	return s.mediaRepo.Create(media)
}

// ProcessFileAsync processes a file asynchronously (thumbnail generation, etc.)
func (s *MediaService) ProcessFileAsync(ctx context.Context, media *models.MediaItem) {
	s.processFileAsync(ctx, media)
}

// GetMedia retrieves a media item by ID
func (s *MediaService) GetMedia(ctx context.Context, id string) (*models.MediaItem, error) {
	return s.mediaRepo.GetByID(id)
}

// StreamMedia streams a media file
func (s *MediaService) StreamMedia(ctx context.Context, id string) (io.ReadCloser, error) {
	media, err := s.mediaRepo.GetByID(id)
	if err != nil {
		return nil, err
	}

	return s.storage.GetFile(ctx, media.FilePath)
}

// GetThumbnail retrieves a thumbnail for a media item
func (s *MediaService) GetThumbnail(ctx context.Context, id string) (io.ReadCloser, error) {
	media, err := s.mediaRepo.GetByID(id)
	if err != nil {
		return nil, err
	}

	if media.ThumbnailPath == nil {
		return nil, fmt.Errorf("thumbnail not available")
	}

	return s.storage.GetFile(ctx, *media.ThumbnailPath)
}

// UpdateMedia updates media metadata
func (s *MediaService) UpdateMedia(ctx context.Context, id string, req models.MediaUpdateRequest, userID string) (*models.MediaItem, error) {
	media, err := s.mediaRepo.GetByID(id)
	if err != nil {
		return nil, err
	}

	// Check ownership
	if media.UserID != userID {
		return nil, fmt.Errorf("not authorized to update this media")
	}

	// Update fields
	media.Title = req.Title
	media.Description = req.Description
	media.Categories = req.Categories

	// Save to database
	if err := s.mediaRepo.Update(media); err != nil {
		return nil, fmt.Errorf("failed to update media: %w", err)
	}

	return media, nil
}

// DeleteMedia deletes a media item
func (s *MediaService) DeleteMedia(ctx context.Context, id string, userID string) error {
	media, err := s.mediaRepo.GetByID(id)
	if err != nil {
		return err
	}

	// Check ownership
	if media.UserID != userID {
		return fmt.Errorf("not authorized to delete this media")
	}

	// Delete from storage
	if err := s.storage.DeleteFile(ctx, media.FilePath); err != nil {
		logrus.Warnf("Failed to delete file from storage: %v", err)
	}

	// Delete thumbnail if exists
	if media.ThumbnailPath != nil {
		s.storage.DeleteFile(ctx, *media.ThumbnailPath)
	}

	// Delete from database
	return s.mediaRepo.Delete(id)
}

// ListMedia retrieves media items with filtering and pagination
func (s *MediaService) ListMedia(ctx context.Context, query models.MediaQuery) (*models.MediaListResponse, error) {
	query.SetDefaults()

	mediaItems, total, err := s.mediaRepo.List(query)
	if err != nil {
		return nil, fmt.Errorf("failed to list media: %w", err)
	}

	return &models.MediaListResponse{
		Media: mediaItems,
		Total: total,
		Page:  query.Page,
		Limit: query.Limit,
	}, nil
}

// validateFile validates uploaded file
func (s *MediaService) validateFile(file *multipart.FileHeader) error {
	// Check file size with proper type-specific limits
	ext := strings.ToLower(filepath.Ext(file.Filename))
	isImage := s.isImageExtension(ext)
	isVideo := s.isVideoExtension(ext)

	if isImage && file.Size > s.config.MaxImageSize {
		return fmt.Errorf("image file too large: %d bytes (max: %d)", file.Size, s.config.MaxImageSize)
	}
	if isVideo && file.Size > s.config.MaxVideoSize {
		return fmt.Errorf("video file too large: %d bytes (max: %d)", file.Size, s.config.MaxVideoSize)
	}
	if !isImage && !isVideo {
		return fmt.Errorf("unsupported file type: %s", ext)
	}

	// Validate MIME type (allow application/octet-stream for Flutter uploads)
	contentType := file.Header.Get("Content-Type")
	if contentType != "" && contentType != "application/octet-stream" && !s.isValidMimeType(contentType) {
		return fmt.Errorf("invalid MIME type: %s", contentType)
	}

	// Additional security checks
	if file.Filename == "" {
		return fmt.Errorf("filename cannot be empty")
	}

	// Check for directory traversal attempts
	if strings.Contains(file.Filename, "..") || strings.Contains(file.Filename, "/") || strings.Contains(file.Filename, "\\") {
		return fmt.Errorf("invalid filename: contains path traversal characters")
	}

	return nil
}

// determineMediaType determines if the file is an image or video
func (s *MediaService) determineMediaType(filename, contentType string) models.MediaType {
	ext := strings.ToLower(filepath.Ext(filename))

	switch ext {
	case ".jpg", ".jpeg", ".png", ".webp":
		return models.MediaTypeImage
	case ".mp4", ".webm":
		return models.MediaTypeVideo
	default:
		// Fallback to MIME type
		if strings.HasPrefix(contentType, "image/") {
			return models.MediaTypeImage
		} else if strings.HasPrefix(contentType, "video/") {
			return models.MediaTypeVideo
		}
		return models.MediaTypeImage // Default fallback
	}
}

// isValidMimeType checks if the MIME type is valid
func (s *MediaService) isValidMimeType(contentType string) bool {
	validTypes := []string{
		"image/jpeg", "image/jpg", "image/png", "image/webp",
		"video/mp4", "video/webm",
	}

	for _, validType := range validTypes {
		if contentType == validType {
			return true
		}
	}

	return false
}

// isImageExtension checks if the file extension is for an image
func (s *MediaService) isImageExtension(ext string) bool {
	imageExts := []string{".jpg", ".jpeg", ".png", ".webp"}
	for _, imageExt := range imageExts {
		if ext == imageExt {
			return true
		}
	}
	return false
}

// isVideoExtension checks if the file extension is for a video
func (s *MediaService) isVideoExtension(ext string) bool {
	videoExts := []string{".mp4", ".webm"}
	for _, videoExt := range videoExts {
		if ext == videoExt {
			return true
		}
	}
	return false
}

// processFileAsync processes file in background (thumbnails, metadata extraction)
func (s *MediaService) processFileAsync(ctx context.Context, media *models.MediaItem) {
	logrus.Infof("Processing file: %s", media.ID)

	// Get the file from storage
	fileReader, err := s.storage.GetFile(ctx, media.FilePath)
	if err != nil {
		logrus.Errorf("Failed to get file for processing: %v", err)
		return
	}
	defer fileReader.Close()

	var thumbnailPath *string
	var metadata map[string]interface{}

	// Process based on media type
	switch media.Type {
	case models.MediaTypeImage:
		result, err := s.imageProcessor.ProcessImage(fileReader, media.FilePath)
		if err != nil {
			logrus.Errorf("Failed to process image: %v", err)
			return
		}

		// Save thumbnail
		if result.ThumbnailData != nil {
			thumbPath := s.pathGenerator.GenerateThumbnailPath(media.FilePath)
			thumbReader := bytes.NewReader(result.ThumbnailData)
			if err := s.storage.SaveFile(ctx, thumbPath, thumbReader); err != nil {
				logrus.Errorf("Failed to save thumbnail: %v", err)
			} else {
				thumbnailPath = &thumbPath
			}
		}

		metadata = result.Metadata

	case models.MediaTypeVideo:
		result, err := s.videoProcessor.ProcessVideo(fileReader, media.FilePath)
		if err != nil {
			logrus.Errorf("Failed to process video: %v", err)
			return
		}

		// Save thumbnail
		if result.ThumbnailData != nil {
			thumbPath := s.pathGenerator.GenerateThumbnailPath(media.FilePath)
			thumbReader := bytes.NewReader(result.ThumbnailData)
			if err := s.storage.SaveFile(ctx, thumbPath, thumbReader); err != nil {
				logrus.Errorf("Failed to save thumbnail: %v", err)
			} else {
				thumbnailPath = &thumbPath
			}
		}

		metadata = result.Metadata
	}

	// Update media item with processing results
	media.ThumbnailPath = thumbnailPath
	media.Metadata = metadata

	// Save updated media item
	if err := s.mediaRepo.Update(media); err != nil {
		logrus.Errorf("Failed to update media with processing results: %v", err)
		return
	}

	logrus.Infof("File processing completed: %s", media.ID)
}
