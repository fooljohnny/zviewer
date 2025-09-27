package handlers

import (
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	"zviewer-server/internal/repositories"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// MediaHandler handles media-related requests
type MediaHandler struct {
	mediaRepo *repositories.MediaRepository
	logger    *logrus.Logger
	basePath  string
}

// NewMediaHandler creates a new media handler
func NewMediaHandler(mediaRepo *repositories.MediaRepository, logger *logrus.Logger, basePath string) *MediaHandler {
	return &MediaHandler{
		mediaRepo: mediaRepo,
		logger:    logger,
		basePath:  basePath,
	}
}

// StreamMedia handles streaming media files
func (h *MediaHandler) StreamMedia(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Media ID required"})
		return
	}

	// Get media info from database
	media, err := h.mediaRepo.GetByID(id)
	if err != nil {
		h.logger.Warnf("Media not found: %s, error: %v", id, err)
		c.JSON(http.StatusNotFound, gin.H{"message": "Media not found"})
		return
	}

	// Construct full file path
	fullPath := filepath.Join(h.basePath, media.FilePath)

	// Check if file exists
	if _, err := os.Stat(fullPath); os.IsNotExist(err) {
		h.logger.Warnf("Media file not found: %s", fullPath)
		c.JSON(http.StatusNotFound, gin.H{"message": "Media file not found"})
		return
	}

	// Open file
	file, err := os.Open(fullPath)
	if err != nil {
		h.logger.Errorf("Failed to open media file: %s, error: %v", fullPath, err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to open media file"})
		return
	}
	defer file.Close()

	// Get file info
	fileInfo, err := file.Stat()
	if err != nil {
		h.logger.Errorf("Failed to get file info: %s, error: %v", fullPath, err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to get file info"})
		return
	}

	// Set appropriate headers
	c.Header("Content-Type", media.MimeType)
	c.Header("Content-Length", strconv.FormatInt(fileInfo.Size(), 10))
	c.Header("Cache-Control", "public, max-age=3600")

	// Stream the file
	c.DataFromReader(http.StatusOK, fileInfo.Size(), media.MimeType, file, nil)
}

// GetThumbnail handles getting thumbnails
func (h *MediaHandler) GetThumbnail(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Media ID required"})
		return
	}

	// Get media info from database
	media, err := h.mediaRepo.GetByID(id)
	if err != nil {
		h.logger.Warnf("Media not found: %s, error: %v", id, err)
		c.JSON(http.StatusNotFound, gin.H{"message": "Media not found"})
		return
	}

	// Check if thumbnail exists
	if media.ThumbnailPath == nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Thumbnail not available"})
		return
	}

	// Construct full thumbnail path
	fullPath := filepath.Join(h.basePath, *media.ThumbnailPath)

	// Check if thumbnail file exists
	if _, err := os.Stat(fullPath); os.IsNotExist(err) {
		h.logger.Warnf("Thumbnail file not found: %s", fullPath)
		c.JSON(http.StatusNotFound, gin.H{"message": "Thumbnail file not found"})
		return
	}

	// Open thumbnail file
	file, err := os.Open(fullPath)
	if err != nil {
		h.logger.Errorf("Failed to open thumbnail file: %s, error: %v", fullPath, err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to open thumbnail file"})
		return
	}
	defer file.Close()

	// Get file info
	fileInfo, err := file.Stat()
	if err != nil {
		h.logger.Errorf("Failed to get thumbnail file info: %s, error: %v", fullPath, err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to get thumbnail file info"})
		return
	}

	// Set appropriate headers
	c.Header("Content-Type", "image/jpeg")
	c.Header("Content-Length", strconv.FormatInt(fileInfo.Size(), 10))
	c.Header("Cache-Control", "public, max-age=86400") // Cache for 24 hours

	// Stream the thumbnail
	c.DataFromReader(http.StatusOK, fileInfo.Size(), "image/jpeg", file, nil)
}
