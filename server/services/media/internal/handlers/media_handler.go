package handlers

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"zviewer-media-service/internal/models"
	"zviewer-media-service/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// MediaHandler handles HTTP requests for media operations
type MediaHandler struct {
	mediaService  *services.MediaService
	uploadService *services.UploadService
	wsHandler     *WebSocketHandler
}

// NewMediaHandler creates a new media handler
func NewMediaHandler(mediaService *services.MediaService, uploadService *services.UploadService, wsHandler *WebSocketHandler) *MediaHandler {
	return &MediaHandler{
		mediaService:  mediaService,
		uploadService: uploadService,
		wsHandler:     wsHandler,
	}
}

// UploadMedia handles file upload requests
func (h *MediaHandler) UploadMedia(c *gin.Context) {
	// Get user info from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "User ID not found"})
		return
	}

	userName, _ := c.Get("user_name")

	// Parse multipart form
	form, err := c.MultipartForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Failed to parse multipart form"})
		return
	}

	// Get files
	files := form.File["file"]
	if len(files) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"message": "No file provided"})
		return
	}

	// Parse request data
	var req models.MediaUploadRequest
	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid request data"})
		return
	}

	// Upload multiple media files
	var uploadedMedia []models.Media
	var errors []string
	
	for i, file := range files {
		// Create individual request for each file
		fileReq := req
		if len(files) > 1 {
			// For multiple files, use individual metadata if available
			fileReq.Title = c.PostForm(fmt.Sprintf("files[%d].title", i))
			fileReq.Description = c.PostForm(fmt.Sprintf("files[%d].description", i))
			fileReq.Category = c.PostForm(fmt.Sprintf("files[%d].category", i))
			fileReq.Tags = strings.Split(c.PostForm(fmt.Sprintf("files[%d].tags", i)), ",")
		}
		
		// If individual metadata is not available, use the main request
		if fileReq.Title == "" {
			fileReq.Title = req.Title
		}
		if fileReq.Description == "" {
			fileReq.Description = req.Description
		}
		if fileReq.Category == "" {
			fileReq.Category = req.Category
		}
		if len(fileReq.Tags) == 0 {
			fileReq.Tags = req.Tags
		}

		// Upload single media
		media, err := h.mediaService.UploadMedia(c.Request.Context(), file, fileReq, userID.(string), userName.(string))
		if err != nil {
			logrus.Errorf("Failed to upload media file %s: %v", file.Filename, err)
			errors = append(errors, fmt.Sprintf("Failed to upload %s: %v", file.Filename, err))
			continue
		}
		
		uploadedMedia = append(uploadedMedia, *media)
	}

	// Prepare response
	response := gin.H{
		"success": len(uploadedMedia) > 0,
		"message": fmt.Sprintf("Successfully uploaded %d of %d files", len(uploadedMedia), len(files)),
		"uploaded_media": uploadedMedia,
		"successful_uploads": len(uploadedMedia),
		"failed_uploads": len(errors),
		"errors": errors,
	}

	if len(uploadedMedia) > 0 {
		c.JSON(http.StatusCreated, response)
	} else {
		c.JSON(http.StatusInternalServerError, response)
	}
}

// GetMedia handles getting a media item by ID
func (h *MediaHandler) GetMedia(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Media ID required"})
		return
	}

	media, err := h.mediaService.GetMedia(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Media not found"})
		return
	}

	c.JSON(http.StatusOK, media)
}

// StreamMedia handles streaming media files
func (h *MediaHandler) StreamMedia(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Media ID required"})
		return
	}

	// Get media info first
	media, err := h.mediaService.GetMedia(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Media not found"})
		return
	}

	// Get file stream
	fileReader, err := h.mediaService.StreamMedia(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to stream media"})
		return
	}
	defer fileReader.Close()

	// Set appropriate headers
	c.Header("Content-Type", media.MimeType)
	c.Header("Content-Length", strconv.FormatInt(media.FileSize, 10))
	c.Header("Cache-Control", "public, max-age=3600")

	// Stream the file
	c.DataFromReader(http.StatusOK, media.FileSize, media.MimeType, fileReader, nil)
}

// GetThumbnail handles getting thumbnails
func (h *MediaHandler) GetThumbnail(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Media ID required"})
		return
	}

	// Get thumbnail stream
	thumbnailReader, err := h.mediaService.GetThumbnail(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Thumbnail not available"})
		return
	}
	defer thumbnailReader.Close()

	// Set appropriate headers
	c.Header("Content-Type", "image/jpeg")
	c.Header("Cache-Control", "public, max-age=86400") // Cache for 24 hours

	// Stream the thumbnail
	c.DataFromReader(http.StatusOK, -1, "image/jpeg", thumbnailReader, nil)
}

// UpdateMedia handles updating media metadata
func (h *MediaHandler) UpdateMedia(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Media ID required"})
		return
	}

	// Get user info from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "User ID not found"})
		return
	}

	// Parse request data
	var req models.MediaUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid request data"})
		return
	}

	// Update media
	media, err := h.mediaService.UpdateMedia(c.Request.Context(), id, req, userID.(string))
	if err != nil {
		logrus.Errorf("Failed to update media: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to update media"})
		return
	}

	c.JSON(http.StatusOK, media)
}

// DeleteMedia handles deleting media
func (h *MediaHandler) DeleteMedia(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Media ID required"})
		return
	}

	// Get user info from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "User ID not found"})
		return
	}

	// Delete media
	err := h.mediaService.DeleteMedia(c.Request.Context(), id, userID.(string))
	if err != nil {
		logrus.Errorf("Failed to delete media: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to delete media"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Media deleted successfully"})
}

// ListMedia handles listing media with pagination and filtering
func (h *MediaHandler) ListMedia(c *gin.Context) {
	// Parse query parameters
	var query models.MediaQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid query parameters"})
		return
	}

	// List media
	response, err := h.mediaService.ListMedia(c.Request.Context(), query)
	if err != nil {
		logrus.Errorf("Failed to list media: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to list media"})
		return
	}

	c.JSON(http.StatusOK, response)
}

// StartChunkedUpload initializes a new chunked upload session
func (h *MediaHandler) StartChunkedUpload(c *gin.Context) {
	// Get user info from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "User ID not found"})
		return
	}

	// Parse request data
	var req models.ChunkedUploadRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid request data"})
		return
	}

	// Start chunked upload
	chunkedUpload := h.uploadService.StartChunkedUpload(userID.(string), req)

	response := &models.ChunkedUploadResponse{
		UploadID:   chunkedUpload.UploadID,
		ChunkIndex: 0,
		Received:   false,
		Progress:   0.0,
		IsComplete: false,
	}

	c.JSON(http.StatusOK, response)
}

// UploadChunk handles uploading a single chunk
func (h *MediaHandler) UploadChunk(c *gin.Context) {
	// Get user info from context
	_, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "User ID not found"})
		return
	}

	// Parse multipart form
	form, err := c.MultipartForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Failed to parse multipart form"})
		return
	}

	// Get chunk data
	files := form.File["chunk"]
	if len(files) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"message": "No chunk data provided"})
		return
	}

	file := files[0]

	// Get upload ID and chunk index from form
	uploadID := c.PostForm("uploadId")
	chunkIndexStr := c.PostForm("chunkIndex")
	if uploadID == "" || chunkIndexStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "uploadId and chunkIndex required"})
		return
	}

	chunkIndex, err := strconv.Atoi(chunkIndexStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid chunkIndex"})
		return
	}

	// Read chunk data
	src, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to read chunk data"})
		return
	}
	defer src.Close()

	chunkData := make([]byte, file.Size)
	_, err = src.Read(chunkData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to read chunk data"})
		return
	}

	// Add chunk to upload service
	response, err := h.uploadService.AddChunk(uploadID, chunkIndex, chunkData)
	if err != nil {
		logrus.Errorf("Failed to add chunk: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to add chunk"})
		return
	}

	// Broadcast progress via WebSocket
	if progress, exists := h.uploadService.GetProgress(uploadID); exists {
		h.wsHandler.BroadcastProgress(uploadID, progress)
	}

	// If upload is complete, process the file
	if response.IsComplete {
		go func() {
			media, err := h.uploadService.CompleteChunkedUpload(c.Request.Context(), uploadID)
			if err != nil {
				logrus.Errorf("Failed to complete chunked upload: %v", err)
				h.wsHandler.BroadcastError(uploadID, "Failed to complete upload")
				return
			}

			// Save to database
			if err := h.mediaService.SaveMedia(c.Request.Context(), media); err != nil {
				logrus.Errorf("Failed to save media: %v", err)
				h.wsHandler.BroadcastError(uploadID, "Failed to save media")
				return
			}

			// Process file in background
			go h.mediaService.ProcessFileAsync(context.Background(), media)

			// Update progress
			h.uploadService.CompleteUpload(uploadID)
			if progress, exists := h.uploadService.GetProgress(uploadID); exists {
				progress.Status = "completed"
				h.wsHandler.BroadcastProgress(uploadID, progress)
			}
		}()
	}

	c.JSON(http.StatusOK, response)
}

// GetUploadProgress retrieves upload progress
func (h *MediaHandler) GetUploadProgress(c *gin.Context) {
	uploadID := c.Param("uploadId")
	if uploadID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Upload ID required"})
		return
	}

	progress, exists := h.uploadService.GetProgress(uploadID)
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"message": "Upload not found"})
		return
	}

	c.JSON(http.StatusOK, progress)
}

// HandleWebSocket handles WebSocket connections for upload progress
func (h *MediaHandler) HandleWebSocket(c *gin.Context) {
	h.wsHandler.HandleWebSocket(c)
}
