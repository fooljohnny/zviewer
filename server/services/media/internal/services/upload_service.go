package services

import (
	"context"
	"fmt"
	"path/filepath"
	"sync"
	"time"

	"zviewer-media-service/internal/config"
	"zviewer-media-service/internal/models"
	"zviewer-media-service/internal/storage"

	"github.com/google/uuid"
)

// UploadService manages upload progress and chunked uploads
type UploadService struct {
	progressMap map[string]*models.UploadProgress
	chunkMap    map[string]*ChunkedUpload
	mu          sync.RWMutex
	storage     storage.Storage
	pathGen     *storage.PathGenerator
	config      *config.Config
}

// ChunkedUpload represents a chunked upload session
type ChunkedUpload struct {
	UploadID     string
	UserID       string
	FileName     string
	FileSize     int64
	TotalChunks  int
	ChunkSize    int64
	Chunks       map[int][]byte
	Received     map[int]bool
	Title        string
	Description  string
	Categories   []string
	CreatedAt    time.Time
	LastActivity time.Time
	mu           sync.RWMutex
}

// NewUploadService creates a new upload service
func NewUploadService(storage storage.Storage, pathGen *storage.PathGenerator, config *config.Config) *UploadService {
	service := &UploadService{
		progressMap: make(map[string]*models.UploadProgress),
		chunkMap:    make(map[string]*ChunkedUpload),
		storage:     storage,
		pathGen:     pathGen,
		config:      config,
	}

	// Start cleanup routine for expired uploads
	go service.cleanupExpiredUploads()

	return service
}

// StartUpload initializes a new upload session
func (s *UploadService) StartUpload(userID, fileName string, fileSize int64, title, description string, categories []string) *models.UploadProgress {
	uploadID := uuid.New().String()

	progress := &models.UploadProgress{
		UploadID:     uploadID,
		UserID:       userID,
		FileName:     fileName,
		FileSize:     fileSize,
		UploadedSize: 0,
		Progress:     0.0,
		Status:       "uploading",
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	s.mu.Lock()
	s.progressMap[uploadID] = progress
	s.mu.Unlock()

	return progress
}

// UpdateProgress updates the upload progress
func (s *UploadService) UpdateProgress(uploadID string, uploadedSize int64) {
	s.mu.Lock()
	defer s.mu.Unlock()

	progress, exists := s.progressMap[uploadID]
	if !exists {
		return
	}

	progress.UploadedSize = uploadedSize
	progress.Progress = float64(uploadedSize) / float64(progress.FileSize)
	progress.UpdatedAt = time.Now()

	// Mark as completed if fully uploaded
	if uploadedSize >= progress.FileSize {
		progress.Status = "processing"
		progress.Progress = 1.0
	}
}

// CompleteUpload marks an upload as completed
func (s *UploadService) CompleteUpload(uploadID string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	progress, exists := s.progressMap[uploadID]
	if !exists {
		return
	}

	progress.Status = "completed"
	progress.Progress = 1.0
	progress.UpdatedAt = time.Now()
}

// FailUpload marks an upload as failed
func (s *UploadService) FailUpload(uploadID string, errorMsg string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	progress, exists := s.progressMap[uploadID]
	if !exists {
		return
	}

	progress.Status = "failed"
	progress.Error = errorMsg
	progress.UpdatedAt = time.Now()
}

// GetProgress retrieves upload progress
func (s *UploadService) GetProgress(uploadID string) (*models.UploadProgress, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	progress, exists := s.progressMap[uploadID]
	return progress, exists
}

// StartChunkedUpload initializes a new chunked upload session
func (s *UploadService) StartChunkedUpload(userID string, req models.ChunkedUploadRequest) *ChunkedUpload {
	chunkedUpload := &ChunkedUpload{
		UploadID:     req.UploadID,
		UserID:       userID,
		FileName:     req.FileName,
		FileSize:     req.FileSize,
		TotalChunks:  req.TotalChunks,
		ChunkSize:    req.ChunkSize,
		Chunks:       make(map[int][]byte),
		Received:     make(map[int]bool),
		Title:        req.Title,
		Description:  req.Description,
		Categories:   req.Categories,
		CreatedAt:    time.Now(),
		LastActivity: time.Now(),
	}

	s.mu.Lock()
	s.chunkMap[req.UploadID] = chunkedUpload
	s.mu.Unlock()

	// Initialize progress tracking
	s.StartUpload(userID, req.FileName, req.FileSize, req.Title, req.Description, req.Categories)

	return chunkedUpload
}

// AddChunk adds a chunk to the chunked upload
func (s *UploadService) AddChunk(uploadID string, chunkIndex int, chunkData []byte) (*models.ChunkedUploadResponse, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	chunkedUpload, exists := s.chunkMap[uploadID]
	if !exists {
		return nil, fmt.Errorf("upload session not found")
	}

	chunkedUpload.mu.Lock()
	defer chunkedUpload.mu.Unlock()

	// Store chunk
	chunkedUpload.Chunks[chunkIndex] = make([]byte, len(chunkData))
	copy(chunkedUpload.Chunks[chunkIndex], chunkData)
	chunkedUpload.Received[chunkIndex] = true
	chunkedUpload.LastActivity = time.Now()

	// Calculate progress
	receivedChunks := len(chunkedUpload.Received)
	progress := float64(receivedChunks) / float64(chunkedUpload.TotalChunks)

	// Update progress
	s.UpdateProgress(uploadID, int64(receivedChunks)*chunkedUpload.ChunkSize)

	// Check if all chunks received
	isComplete := receivedChunks == chunkedUpload.TotalChunks

	response := &models.ChunkedUploadResponse{
		UploadID:   uploadID,
		ChunkIndex: chunkIndex,
		Received:   true,
		Progress:   progress,
		IsComplete: isComplete,
	}

	return response, nil
}

// CompleteChunkedUpload assembles all chunks and creates the final file
func (s *UploadService) CompleteChunkedUpload(ctx context.Context, uploadID string) (*models.MediaItem, error) {
	s.mu.Lock()
	chunkedUpload, exists := s.chunkMap[uploadID]
	s.mu.Unlock()

	if !exists {
		return nil, fmt.Errorf("upload session not found")
	}

	chunkedUpload.mu.RLock()
	defer chunkedUpload.mu.RUnlock()

	// Verify all chunks are received
	if len(chunkedUpload.Received) != chunkedUpload.TotalChunks {
		return nil, fmt.Errorf("not all chunks received")
	}

	// Assemble chunks in order
	var fileData []byte
	for i := 0; i < chunkedUpload.TotalChunks; i++ {
		chunk, exists := chunkedUpload.Chunks[i]
		if !exists {
			return nil, fmt.Errorf("chunk %d not found", i)
		}
		fileData = append(fileData, chunk...)
	}

	// Verify file size
	if int64(len(fileData)) != chunkedUpload.FileSize {
		return nil, fmt.Errorf("file size mismatch: expected %d, got %d", chunkedUpload.FileSize, len(fileData))
	}

	// Generate file path
	filePath, fileID, err := s.pathGen.GeneratePath(chunkedUpload.UserID, chunkedUpload.FileName)
	if err != nil {
		return nil, fmt.Errorf("failed to generate file path: %w", err)
	}

	// Save file to storage
	if err := s.storage.SaveFileFromBytes(ctx, filePath, fileData); err != nil {
		return nil, fmt.Errorf("failed to save file: %w", err)
	}

	// Determine media type
	mediaType := s.determineMediaType(chunkedUpload.FileName)

	// Create media item
	media := &models.MediaItem{
		ID:          fileID,
		Title:       chunkedUpload.Title,
		Description: chunkedUpload.Description,
		FilePath:    filePath,
		Type:        mediaType,
		UserID:      chunkedUpload.UserID,
		UserName:    "", // Will be set by the caller
		Status:      models.MediaStatusPending,
		Categories:  chunkedUpload.Categories,
		UploadedAt:  time.Now(),
		FileSize:    chunkedUpload.FileSize,
		MimeType:    s.getMimeType(chunkedUpload.FileName),
		Metadata:    make(map[string]interface{}),
	}

	// Mark upload as completed
	s.CompleteUpload(uploadID)

	// Clean up chunked upload
	s.mu.Lock()
	delete(s.chunkMap, uploadID)
	s.mu.Unlock()

	return media, nil
}

// determineMediaType determines the media type based on file extension
func (s *UploadService) determineMediaType(fileName string) models.MediaType {
	ext := filepath.Ext(fileName)
	switch ext {
	case ".jpg", ".jpeg", ".png", ".webp":
		return models.MediaTypeImage
	case ".mp4", ".webm":
		return models.MediaTypeVideo
	default:
		return models.MediaTypeImage // Default to image
	}
}

// getMimeType returns the MIME type based on file extension
func (s *UploadService) getMimeType(fileName string) string {
	ext := filepath.Ext(fileName)
	switch ext {
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".png":
		return "image/png"
	case ".webp":
		return "image/webp"
	case ".mp4":
		return "video/mp4"
	case ".webm":
		return "video/webm"
	default:
		return "application/octet-stream"
	}
}

// cleanupExpiredUploads removes expired upload sessions
func (s *UploadService) cleanupExpiredUploads() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		s.mu.Lock()
		now := time.Now()

		// Clean up expired progress entries (older than 1 hour)
		for uploadID, progress := range s.progressMap {
			if now.Sub(progress.CreatedAt) > time.Hour {
				delete(s.progressMap, uploadID)
			}
		}

		// Clean up expired chunked uploads (older than 2 hours)
		for uploadID, chunkedUpload := range s.chunkMap {
			if now.Sub(chunkedUpload.LastActivity) > 2*time.Hour {
				delete(s.chunkMap, uploadID)
			}
		}

		s.mu.Unlock()
	}
}
