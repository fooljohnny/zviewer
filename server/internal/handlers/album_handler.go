package handlers

import (
	"net/http"
	"strconv"

	"zviewer-server/internal/models"
	"zviewer-server/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// AlbumHandler handles album HTTP requests
type AlbumHandler struct {
	albumService *services.AlbumService
	logger       *logrus.Logger
}

// NewAlbumHandler creates a new album handler
func NewAlbumHandler(albumService *services.AlbumService, logger *logrus.Logger) *AlbumHandler {
	return &AlbumHandler{
		albumService: albumService,
		logger:       logger,
	}
}

// CreateAlbum creates a new album
// @Summary Create a new album
// @Description Create a new album with the provided information
// @Tags albums
// @Accept json
// @Produce json
// @Param request body models.CreateAlbumRequest true "Album creation request"
// @Success 201 {object} models.AlbumActionResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 401 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /api/admin/albums [post]
func (h *AlbumHandler) CreateAlbum(c *gin.Context) {
	var req models.CreateAlbumRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.WithError(err).Error("Failed to bind create album request")
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Invalid request format: " + err.Error(),
		})
		return
	}

	// Get user ID from context (set by auth middleware)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Message: "User not authenticated",
		})
		return
	}

	album, err := h.albumService.CreateAlbum(&req, userID.(string))
	if err != nil {
		h.logger.WithError(err).Error("Failed to create album")
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Message: "Failed to create album: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, models.AlbumActionResponse{
		Success: true,
		Message: "Album created successfully",
		Album:   album,
	})
}

// GetAlbum retrieves an album by ID
// @Summary Get album by ID
// @Description Get album details by ID
// @Tags albums
// @Produce json
// @Param id path string true "Album ID"
// @Success 200 {object} models.AlbumActionResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /api/admin/albums/{id} [get]
func (h *AlbumHandler) GetAlbum(c *gin.Context) {
	albumID := c.Param("id")
	if albumID == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Album ID is required",
		})
		return
	}

	album, err := h.albumService.GetAlbum(albumID)
	if err != nil {
		h.logger.WithError(err).Error("Failed to get album")
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Message: "Album not found: " + err.Error(),
		})
		return
	}

	// Increment view count
	go func() {
		if err := h.albumService.IncrementViewCount(albumID); err != nil {
			h.logger.WithError(err).Warn("Failed to increment view count")
		}
	}()

	c.JSON(http.StatusOK, models.AlbumActionResponse{
		Success: true,
		Message: "Album retrieved successfully",
		Album:   album,
	})
}

// GetAlbums retrieves albums with pagination
// @Summary Get albums
// @Description Get albums with pagination and filtering
// @Tags albums
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(20)
// @Param user_id query string false "Filter by user ID"
// @Param public query bool false "Filter public albums only"
// @Success 200 {object} models.AlbumListResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /api/admin/albums [get]
func (h *AlbumHandler) GetAlbums(c *gin.Context) {
	// Parse query parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	userID := c.Query("user_id")
	publicOnly := c.Query("public") == "true"

	// Validate parameters
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	var response *models.AlbumListResponse
	var err error

	if publicOnly {
		response, err = h.albumService.GetPublicAlbums(page, limit)
	} else if userID != "" {
		response, err = h.albumService.GetAlbumsByUser(userID, page, limit)
	} else {
		// Get current user's albums
		currentUserID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Message: "User not authenticated",
			})
			return
		}
		response, err = h.albumService.GetAlbumsByUser(currentUserID.(string), page, limit)
	}

	if err != nil {
		h.logger.WithError(err).Error("Failed to get albums")
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Message: "Failed to get albums: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// UpdateAlbum updates an album
// @Summary Update album
// @Description Update album information
// @Tags albums
// @Accept json
// @Produce json
// @Param id path string true "Album ID"
// @Param request body models.UpdateAlbumRequest true "Album update request"
// @Success 200 {object} models.AlbumActionResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 401 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /api/admin/albums/{id} [put]
func (h *AlbumHandler) UpdateAlbum(c *gin.Context) {
	albumID := c.Param("id")
	if albumID == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Album ID is required",
		})
		return
	}

	var req models.UpdateAlbumRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.WithError(err).Error("Failed to bind update album request")
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Invalid request format: " + err.Error(),
		})
		return
	}

	// Get user ID from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Message: "User not authenticated",
		})
		return
	}

	album, err := h.albumService.UpdateAlbum(albumID, &req, userID.(string))
	if err != nil {
		h.logger.WithError(err).Error("Failed to update album")
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Message: "Failed to update album: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.AlbumActionResponse{
		Success: true,
		Message: "Album updated successfully",
		Album:   album,
	})
}

// DeleteAlbum deletes an album
// @Summary Delete album
// @Description Delete an album
// @Tags albums
// @Param id path string true "Album ID"
// @Success 200 {object} models.AlbumActionResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 401 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /api/admin/albums/{id} [delete]
func (h *AlbumHandler) DeleteAlbum(c *gin.Context) {
	albumID := c.Param("id")
	if albumID == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Album ID is required",
		})
		return
	}

	// Get user ID from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Message: "User not authenticated",
		})
		return
	}

	err := h.albumService.DeleteAlbum(albumID, userID.(string))
	if err != nil {
		h.logger.WithError(err).Error("Failed to delete album")
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Message: "Failed to delete album: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.AlbumActionResponse{
		Success: true,
		Message: "Album deleted successfully",
	})
}

// AddImagesToAlbum adds images to an album
// @Summary Add images to album
// @Description Add images to an existing album
// @Tags albums
// @Accept json
// @Produce json
// @Param id path string true "Album ID"
// @Param request body models.AddImageToAlbumRequest true "Add images request"
// @Success 200 {object} models.AlbumActionResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 401 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /api/admin/albums/{id}/images [post]
func (h *AlbumHandler) AddImagesToAlbum(c *gin.Context) {
	albumID := c.Param("id")
	if albumID == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Album ID is required",
		})
		return
	}

	var req models.AddImageToAlbumRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.WithError(err).Error("Failed to bind add images request")
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Invalid request format: " + err.Error(),
		})
		return
	}

	// Get user ID from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Message: "User not authenticated",
		})
		return
	}

	err := h.albumService.AddImagesToAlbum(albumID, &req, userID.(string))
	if err != nil {
		h.logger.WithError(err).Error("Failed to add images to album")
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Message: "Failed to add images to album: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.AlbumActionResponse{
		Success: true,
		Message: "Images added to album successfully",
	})
}

// RemoveImagesFromAlbum removes images from an album
// @Summary Remove images from album
// @Description Remove images from an existing album
// @Tags albums
// @Accept json
// @Produce json
// @Param id path string true "Album ID"
// @Param request body models.RemoveImageFromAlbumRequest true "Remove images request"
// @Success 200 {object} models.AlbumActionResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 401 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /api/admin/albums/{id}/images [delete]
func (h *AlbumHandler) RemoveImagesFromAlbum(c *gin.Context) {
	albumID := c.Param("id")
	if albumID == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Album ID is required",
		})
		return
	}

	var req models.RemoveImageFromAlbumRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.WithError(err).Error("Failed to bind remove images request")
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Invalid request format: " + err.Error(),
		})
		return
	}

	// Get user ID from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Message: "User not authenticated",
		})
		return
	}

	err := h.albumService.RemoveImagesFromAlbum(albumID, &req, userID.(string))
	if err != nil {
		h.logger.WithError(err).Error("Failed to remove images from album")
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Message: "Failed to remove images from album: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.AlbumActionResponse{
		Success: true,
		Message: "Images removed from album successfully",
	})
}

// SetAlbumCover sets the cover image for an album
// @Summary Set album cover
// @Description Set the cover image for an album
// @Tags albums
// @Accept json
// @Produce json
// @Param id path string true "Album ID"
// @Param request body models.SetAlbumCoverRequest true "Set cover request"
// @Success 200 {object} models.AlbumActionResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 401 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /api/admin/albums/{id}/cover [put]
func (h *AlbumHandler) SetAlbumCover(c *gin.Context) {
	albumID := c.Param("id")
	if albumID == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Album ID is required",
		})
		return
	}

	var req models.SetAlbumCoverRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.WithError(err).Error("Failed to bind set cover request")
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Invalid request format: " + err.Error(),
		})
		return
	}

	// Get user ID from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Message: "User not authenticated",
		})
		return
	}

	err := h.albumService.SetAlbumCover(albumID, &req, userID.(string))
	if err != nil {
		h.logger.WithError(err).Error("Failed to set album cover")
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Message: "Failed to set album cover: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.AlbumActionResponse{
		Success: true,
		Message: "Album cover set successfully",
	})
}

// SearchAlbums searches albums
// @Summary Search albums
// @Description Search albums by title, description, or tags
// @Tags albums
// @Produce json
// @Param q query string true "Search query"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(20)
// @Success 200 {object} models.AlbumListResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /api/admin/albums/search [get]
func (h *AlbumHandler) SearchAlbums(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Search query is required",
		})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	// Validate parameters
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	// Get user ID from context (optional for search)
	userID, _ := c.Get("user_id")
	var userIDPtr *string
	if userID != nil {
		userIDStr := userID.(string)
		userIDPtr = &userIDStr
	}

	response, err := h.albumService.SearchAlbums(query, userIDPtr, page, limit)
	if err != nil {
		h.logger.WithError(err).Error("Failed to search albums")
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Message: "Failed to search albums: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, response)
}
