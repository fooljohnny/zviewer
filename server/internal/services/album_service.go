package services

import (
	"fmt"
	"time"

	"zviewer-server/internal/models"
	"zviewer-server/internal/repositories"

	"github.com/sirupsen/logrus"
)

// AlbumService handles album business logic
type AlbumService struct {
	albumRepo *repositories.AlbumRepository
	logger    *logrus.Logger
}

// NewAlbumService creates a new album service
func NewAlbumService(albumRepo *repositories.AlbumRepository, logger *logrus.Logger) *AlbumService {
	return &AlbumService{
		albumRepo: albumRepo,
		logger:    logger,
	}
}

// CreateAlbum creates a new album
func (s *AlbumService) CreateAlbum(req *models.CreateAlbumRequest, userID string) (*models.Album, error) {
	// Validate request
	if err := s.validateCreateRequest(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	// Create album
	album := models.NewAlbum(req.Title, req.Description, userID, req.ImageIDs, req.Tags, req.IsPublic)

	// Save album to database
	if err := s.albumRepo.Create(album); err != nil {
		return nil, fmt.Errorf("failed to create album: %w", err)
	}

	// Add images to album
	for i, imageID := range req.ImageIDs {
		if err := s.albumRepo.AddImageToAlbum(album.ID, imageID, "", userID, i); err != nil {
			s.logger.WithError(err).Warn("Failed to add image to album")
			// Continue with other images
		}
	}

	// Set first image as cover if no cover is specified
	if len(req.ImageIDs) > 0 {
		// Get the first image path (this would need to be fetched from media service)
		// For now, we'll set it as the cover image ID
		album.CoverImageID = &req.ImageIDs[0]
		if err := s.albumRepo.Update(album); err != nil {
			s.logger.WithError(err).Warn("Failed to set album cover")
		}
	}

	s.logger.WithFields(logrus.Fields{
		"album_id": album.ID,
		"user_id":  userID,
		"title":    album.Title,
	}).Info("Album created successfully")

	return album, nil
}

// GetAlbum retrieves an album by ID
func (s *AlbumService) GetAlbum(id string) (*models.Album, error) {
	album, err := s.albumRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get album: %w", err)
	}

	return album, nil
}

// GetAlbumsByUser retrieves albums for a specific user
func (s *AlbumService) GetAlbumsByUser(userID string, page, limit int) (*models.AlbumListResponse, error) {
	offset := (page - 1) * limit

	albums, err := s.albumRepo.GetByUserID(userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get user albums: %w", err)
	}

	total, err := s.albumRepo.GetAlbumCount(&userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get album count: %w", err)
	}

	totalPages := (total + limit - 1) / limit

	return &models.AlbumListResponse{
		Albums:     s.albumsToSlice(albums),
		Total:      total,
		Page:       page,
		Limit:      limit,
		TotalPages: totalPages,
	}, nil
}

// GetPublicAlbums retrieves public albums
func (s *AlbumService) GetPublicAlbums(page, limit int) (*models.AlbumListResponse, error) {
	offset := (page - 1) * limit

	albums, err := s.albumRepo.GetPublic(limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get public albums: %w", err)
	}

	total, err := s.albumRepo.GetAlbumCount(nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get album count: %w", err)
	}

	totalPages := (total + limit - 1) / limit

	return &models.AlbumListResponse{
		Albums:     s.albumsToSlice(albums),
		Total:      total,
		Page:       page,
		Limit:      limit,
		TotalPages: totalPages,
	}, nil
}

// UpdateAlbum updates an album
func (s *AlbumService) UpdateAlbum(id string, req *models.UpdateAlbumRequest, userID string) (*models.Album, error) {
	// Get existing album
	album, err := s.albumRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get album: %w", err)
	}

	// Check if user owns the album
	if album.UserID != userID {
		return nil, fmt.Errorf("unauthorized: user does not own this album")
	}

	// Update fields
	if req.Title != nil {
		album.Title = *req.Title
	}
	if req.Description != nil {
		album.Description = *req.Description
	}
	if req.CoverImageID != nil {
		album.CoverImageID = req.CoverImageID
	}
	if req.Tags != nil {
		album.Tags = req.Tags
	}
	if req.IsPublic != nil {
		album.IsPublic = *req.IsPublic
	}
	if req.Status != nil {
		album.Status = *req.Status
	}

	album.UpdatedAt = time.Now()

	// Update images if provided
	if req.ImageIDs != nil {
		// Remove all existing images
		existingImages, err := s.albumRepo.GetAlbumImages(id)
		if err != nil {
			s.logger.WithError(err).Warn("Failed to get existing album images")
		} else {
			for _, image := range existingImages {
				if err := s.albumRepo.RemoveImageFromAlbum(id, image.ImageID); err != nil {
					s.logger.WithError(err).Warn("Failed to remove image from album")
				}
			}
		}

		// Add new images
		for i, imageID := range req.ImageIDs {
			if err := s.albumRepo.AddImageToAlbum(id, imageID, "", userID, i); err != nil {
				s.logger.WithError(err).Warn("Failed to add image to album")
			}
		}
		album.ImageCount = len(req.ImageIDs)
	}

	// Save updated album
	if err := s.albumRepo.Update(album); err != nil {
		return nil, fmt.Errorf("failed to update album: %w", err)
	}

	s.logger.WithFields(logrus.Fields{
		"album_id": album.ID,
		"user_id":  userID,
	}).Info("Album updated successfully")

	return album, nil
}

// DeleteAlbum deletes an album
func (s *AlbumService) DeleteAlbum(id string, userID string) error {
	// Get existing album
	album, err := s.albumRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("failed to get album: %w", err)
	}

	// Check if user owns the album
	if album.UserID != userID {
		return fmt.Errorf("unauthorized: user does not own this album")
	}

	// Delete album (cascade will handle album_images)
	if err := s.albumRepo.Delete(id); err != nil {
		return fmt.Errorf("failed to delete album: %w", err)
	}

	s.logger.WithFields(logrus.Fields{
		"album_id": id,
		"user_id":  userID,
	}).Info("Album deleted successfully")

	return nil
}

// AddImagesToAlbum adds images to an album
func (s *AlbumService) AddImagesToAlbum(albumID string, req *models.AddImageToAlbumRequest, userID string) error {
	// Get existing album
	album, err := s.albumRepo.GetByID(albumID)
	if err != nil {
		return fmt.Errorf("failed to get album: %w", err)
	}

	// Check if user owns the album
	if album.UserID != userID {
		return fmt.Errorf("unauthorized: user does not own this album")
	}

	// Add images
	for _, imageID := range req.ImageIDs {
		if err := s.albumRepo.AddImageToAlbum(albumID, imageID, "", userID, album.ImageCount); err != nil {
			s.logger.WithError(err).Warn("Failed to add image to album")
			continue
		}
		album.ImageCount++
	}

	// Update album
	album.UpdatedAt = time.Now()
	if err := s.albumRepo.Update(album); err != nil {
		return fmt.Errorf("failed to update album: %w", err)
	}

	s.logger.WithFields(logrus.Fields{
		"album_id":  albumID,
		"user_id":   userID,
		"image_ids": req.ImageIDs,
	}).Info("Images added to album successfully")

	return nil
}

// RemoveImagesFromAlbum removes images from an album
func (s *AlbumService) RemoveImagesFromAlbum(albumID string, req *models.RemoveImageFromAlbumRequest, userID string) error {
	// Get existing album
	album, err := s.albumRepo.GetByID(albumID)
	if err != nil {
		return fmt.Errorf("failed to get album: %w", err)
	}

	// Check if user owns the album
	if album.UserID != userID {
		return fmt.Errorf("unauthorized: user does not own this album")
	}

	// Remove images
	for _, imageID := range req.ImageIDs {
		if err := s.albumRepo.RemoveImageFromAlbum(albumID, imageID); err != nil {
			s.logger.WithError(err).Warn("Failed to remove image from album")
			continue
		}
		album.ImageCount--
	}

	// Update album
	album.UpdatedAt = time.Now()
	if err := s.albumRepo.Update(album); err != nil {
		return fmt.Errorf("failed to update album: %w", err)
	}

	s.logger.WithFields(logrus.Fields{
		"album_id":  albumID,
		"user_id":   userID,
		"image_ids": req.ImageIDs,
	}).Info("Images removed from album successfully")

	return nil
}

// SetAlbumCover sets the cover image for an album
func (s *AlbumService) SetAlbumCover(albumID string, req *models.SetAlbumCoverRequest, userID string) error {
	// Get existing album
	album, err := s.albumRepo.GetByID(albumID)
	if err != nil {
		return fmt.Errorf("failed to get album: %w", err)
	}

	// Check if user owns the album
	if album.UserID != userID {
		return fmt.Errorf("unauthorized: user does not own this album")
	}

	// Verify image exists in album
	images, err := s.albumRepo.GetAlbumImages(albumID)
	if err != nil {
		return fmt.Errorf("failed to get album images: %w", err)
	}

	var foundImage *models.AlbumImage
	for _, image := range images {
		if image.ImageID == req.ImageID {
			foundImage = &image
			break
		}
	}

	if foundImage == nil {
		return fmt.Errorf("image not found in album")
	}

	// Set cover
	album.UpdateCover(req.ImageID, foundImage.ImagePath, *foundImage.ThumbnailPath)

	if err := s.albumRepo.Update(album); err != nil {
		return fmt.Errorf("failed to update album: %w", err)
	}

	s.logger.WithFields(logrus.Fields{
		"album_id": albumID,
		"user_id":  userID,
		"image_id": req.ImageID,
	}).Info("Album cover set successfully")

	return nil
}

// SearchAlbums searches albums
func (s *AlbumService) SearchAlbums(query string, userID *string, page, limit int) (*models.AlbumListResponse, error) {
	offset := (page - 1) * limit

	albums, err := s.albumRepo.SearchAlbums(query, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to search albums: %w", err)
	}

	total, err := s.albumRepo.GetAlbumCount(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get album count: %w", err)
	}

	totalPages := (total + limit - 1) / limit

	return &models.AlbumListResponse{
		Albums:     s.albumsToSlice(albums),
		Total:      total,
		Page:       page,
		Limit:      limit,
		TotalPages: totalPages,
	}, nil
}

// IncrementViewCount increments the view count for an album
func (s *AlbumService) IncrementViewCount(albumID string) error {
	album, err := s.albumRepo.GetByID(albumID)
	if err != nil {
		return fmt.Errorf("failed to get album: %w", err)
	}

	album.IncrementViewCount()

	if err := s.albumRepo.Update(album); err != nil {
		return fmt.Errorf("failed to update album: %w", err)
	}

	return nil
}

// Helper methods

func (s *AlbumService) validateCreateRequest(req *models.CreateAlbumRequest) error {
	if req.Title == "" {
		return fmt.Errorf("title is required")
	}
	if len(req.Title) > 255 {
		return fmt.Errorf("title too long")
	}
	if len(req.Description) > 2000 {
		return fmt.Errorf("description too long")
	}
	if len(req.ImageIDs) == 0 {
		return fmt.Errorf("at least one image is required")
	}
	return nil
}

func (s *AlbumService) albumsToSlice(albums []*models.Album) []models.Album {
	result := make([]models.Album, len(albums))
	for i, album := range albums {
		result[i] = *album
	}
	return result
}
