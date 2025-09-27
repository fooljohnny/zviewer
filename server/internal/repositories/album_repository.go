package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"zviewer-server/internal/models"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

// AlbumRepository handles album database operations
type AlbumRepository struct {
	db     *sql.DB
	logger *logrus.Logger
}

// NewAlbumRepository creates a new album repository
func NewAlbumRepository(db *sql.DB, logger *logrus.Logger) *AlbumRepository {
	return &AlbumRepository{
		db:     db,
		logger: logger,
	}
}

// Create creates a new album
func (r *AlbumRepository) Create(album *models.Album) error {
	query := `
		INSERT INTO albums (id, title, description, status, user_id, created_at, updated_at, 
		                   metadata, is_public, view_count, like_count, tags)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		RETURNING id, created_at, updated_at`

	args := []interface{}{
		album.ID, album.Title, album.Description, album.Status, album.UserID,
		album.CreatedAt, album.UpdatedAt, album.Metadata, album.IsPublic,
		album.ViewCount, album.LikeCount, album.Tags,
	}

	err := r.db.QueryRow(query, args...).Scan(&album.ID, &album.CreatedAt, &album.UpdatedAt)
	if err != nil {
		r.logger.WithError(err).Error("Failed to create album")
		return fmt.Errorf("failed to create album: %w", err)
	}

	return nil
}

// GetByID retrieves an album by ID
func (r *AlbumRepository) GetByID(id string) (*models.Album, error) {
	query := `
		SELECT id, title, description, cover_image_id, cover_image_path, cover_thumbnail_path,
		       status, user_id, created_at, updated_at, metadata, is_public, 
		       view_count, like_count, tags
		FROM albums 
		WHERE id = $1`

	album := &models.Album{}
	err := r.db.QueryRow(query, id).Scan(
		&album.ID, &album.Title, &album.Description, &album.CoverImageID,
		&album.CoverImagePath, &album.CoverThumbnailPath, &album.Status,
		&album.UserID, &album.CreatedAt, &album.UpdatedAt, &album.Metadata,
		&album.IsPublic, &album.ViewCount, &album.LikeCount, &album.Tags,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("album not found")
		}
		r.logger.WithError(err).Error("Failed to get album by ID")
		return nil, fmt.Errorf("failed to get album: %w", err)
	}

	// Get image count
	album.ImageCount = r.getImageCount(album.ID)
	
	// Get images if needed
	if album.ImageCount > 0 {
		images, err := r.GetAlbumImages(album.ID)
		if err != nil {
			r.logger.WithError(err).Warn("Failed to get album images")
		} else {
			album.Images = images
		}
	}

	return album, nil
}

// GetByUserID retrieves albums by user ID
func (r *AlbumRepository) GetByUserID(userID string, limit, offset int) ([]*models.Album, error) {
	query := `
		SELECT id, title, description, cover_image_id, cover_image_path, cover_thumbnail_path,
		       status, user_id, created_at, updated_at, metadata, is_public, 
		       view_count, like_count, tags
		FROM albums 
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3`

	rows, err := r.db.Query(query, userID, limit, offset)
	if err != nil {
		r.logger.WithError(err).Error("Failed to get albums by user ID")
		return nil, fmt.Errorf("failed to get albums: %w", err)
	}
	defer rows.Close()

	var albums []*models.Album
	for rows.Next() {
		album := &models.Album{}
		err := rows.Scan(
			&album.ID, &album.Title, &album.Description, &album.CoverImageID,
			&album.CoverImagePath, &album.CoverThumbnailPath, &album.Status,
			&album.UserID, &album.CreatedAt, &album.UpdatedAt, &album.Metadata,
			&album.IsPublic, &album.ViewCount, &album.LikeCount, &album.Tags,
		)
		if err != nil {
			r.logger.WithError(err).Error("Failed to scan album row")
			continue
		}

		// Get image count
		album.ImageCount = r.getImageCount(album.ID)
		albums = append(albums, album)
	}

	return albums, nil
}

// GetPublic retrieves public albums
func (r *AlbumRepository) GetPublic(limit, offset int) ([]*models.Album, error) {
	query := `
		SELECT id, title, description, cover_image_id, cover_image_path, cover_thumbnail_path,
		       status, user_id, created_at, updated_at, metadata, is_public, 
		       view_count, like_count, tags
		FROM albums 
		WHERE is_public = true AND status = 'published'
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2`

	rows, err := r.db.Query(query, limit, offset)
	if err != nil {
		r.logger.WithError(err).Error("Failed to get public albums")
		return nil, fmt.Errorf("failed to get public albums: %w", err)
	}
	defer rows.Close()

	var albums []*models.Album
	for rows.Next() {
		album := &models.Album{}
		err := rows.Scan(
			&album.ID, &album.Title, &album.Description, &album.CoverImageID,
			&album.CoverImagePath, &album.CoverThumbnailPath, &album.Status,
			&album.UserID, &album.CreatedAt, &album.UpdatedAt, &album.Metadata,
			&album.IsPublic, &album.ViewCount, &album.LikeCount, &album.Tags,
		)
		if err != nil {
			r.logger.WithError(err).Error("Failed to scan album row")
			continue
		}

		// Get image count
		album.ImageCount = r.getImageCount(album.ID)
		albums = append(albums, album)
	}

	return albums, nil
}

// Update updates an album
func (r *AlbumRepository) Update(album *models.Album) error {
	query := `
		UPDATE albums 
		SET title = $2, description = $3, cover_image_id = $4, cover_image_path = $5,
		    cover_thumbnail_path = $6, status = $7, updated_at = $8, metadata = $9,
		    is_public = $10, view_count = $11, like_count = $12, tags = $13
		WHERE id = $1`

	_, err := r.db.Exec(query,
		album.ID, album.Title, album.Description, album.CoverImageID,
		album.CoverImagePath, album.CoverThumbnailPath, album.Status,
		album.UpdatedAt, album.Metadata, album.IsPublic,
		album.ViewCount, album.LikeCount, album.Tags,
	)

	if err != nil {
		r.logger.WithError(err).Error("Failed to update album")
		return fmt.Errorf("failed to update album: %w", err)
	}

	return nil
}

// Delete deletes an album
func (r *AlbumRepository) Delete(id string) error {
	query := `DELETE FROM albums WHERE id = $1`
	
	_, err := r.db.Exec(query, id)
	if err != nil {
		r.logger.WithError(err).Error("Failed to delete album")
		return fmt.Errorf("failed to delete album: %w", err)
	}

	return nil
}

// GetAlbumImages retrieves images for an album
func (r *AlbumRepository) GetAlbumImages(albumID string) ([]models.AlbumImage, error) {
	query := `
		SELECT id, album_id, image_id, image_path, thumbnail_path, mime_type,
		       file_size, width, height, sort_order, added_at, added_by
		FROM album_images 
		WHERE album_id = $1
		ORDER BY sort_order ASC, added_at ASC`

	rows, err := r.db.Query(query, albumID)
	if err != nil {
		r.logger.WithError(err).Error("Failed to get album images")
		return nil, fmt.Errorf("failed to get album images: %w", err)
	}
	defer rows.Close()

	var images []models.AlbumImage
	for rows.Next() {
		image := models.AlbumImage{}
		err := rows.Scan(
			&image.ID, &image.AlbumID, &image.ImageID, &image.ImagePath,
			&image.ThumbnailPath, &image.MimeType, &image.FileSize,
			&image.Width, &image.Height, &image.SortOrder,
			&image.AddedAt, &image.AddedBy,
		)
		if err != nil {
			r.logger.WithError(err).Error("Failed to scan album image row")
			continue
		}
		images = append(images, image)
	}

	return images, nil
}

// AddImageToAlbum adds an image to an album
func (r *AlbumRepository) AddImageToAlbum(albumID, imageID, imagePath, addedBy string, sortOrder int) error {
	query := `
		INSERT INTO album_images (id, album_id, image_id, image_path, sort_order, added_by, added_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)`

	_, err := r.db.Exec(query, uuid.New().String(), albumID, imageID, imagePath, sortOrder, addedBy, time.Now())
	if err != nil {
		r.logger.WithError(err).Error("Failed to add image to album")
		return fmt.Errorf("failed to add image to album: %w", err)
	}

	return nil
}

// RemoveImageFromAlbum removes an image from an album
func (r *AlbumRepository) RemoveImageFromAlbum(albumID, imageID string) error {
	query := `DELETE FROM album_images WHERE album_id = $1 AND image_id = $2`
	
	_, err := r.db.Exec(query, albumID, imageID)
	if err != nil {
		r.logger.WithError(err).Error("Failed to remove image from album")
		return fmt.Errorf("failed to remove image from album: %w", err)
	}

	return nil
}

// SetAlbumCover sets the cover image for an album
func (r *AlbumRepository) SetAlbumCover(albumID, imageID, imagePath, thumbnailPath string) error {
	query := `
		UPDATE albums 
		SET cover_image_id = $2, cover_image_path = $3, cover_thumbnail_path = $4, updated_at = $5
		WHERE id = $1`

	_, err := r.db.Exec(query, albumID, imageID, imagePath, thumbnailPath, time.Now())
	if err != nil {
		r.logger.WithError(err).Error("Failed to set album cover")
		return fmt.Errorf("failed to set album cover: %w", err)
	}

	return nil
}

// GetImageCount returns the number of images in an album
func (r *AlbumRepository) getImageCount(albumID string) int {
	query := `SELECT COUNT(*) FROM album_images WHERE album_id = $1`
	
	var count int
	err := r.db.QueryRow(query, albumID).Scan(&count)
	if err != nil {
		r.logger.WithError(err).Error("Failed to get image count")
		return 0
	}

	return count
}

// SearchAlbums searches albums by title, description, or tags
func (r *AlbumRepository) SearchAlbums(query string, userID *string, limit, offset int) ([]*models.Album, error) {
	searchQuery := `
		SELECT id, title, description, cover_image_id, cover_image_path, cover_thumbnail_path,
		       status, user_id, created_at, updated_at, metadata, is_public, 
		       view_count, like_count, tags
		FROM albums 
		WHERE (title ILIKE $1 OR description ILIKE $1 OR $2 = ANY(tags))`

	args := []interface{}{"%" + query + "%", query}
	
	if userID != nil {
		searchQuery += " AND user_id = $3"
		args = append(args, *userID)
	}

	searchQuery += " ORDER BY created_at DESC LIMIT $" + fmt.Sprintf("%d", len(args)+1) + " OFFSET $" + fmt.Sprintf("%d", len(args)+2)
	args = append(args, limit, offset)

	rows, err := r.db.Query(searchQuery, args...)
	if err != nil {
		r.logger.WithError(err).Error("Failed to search albums")
		return nil, fmt.Errorf("failed to search albums: %w", err)
	}
	defer rows.Close()

	var albums []*models.Album
	for rows.Next() {
		album := &models.Album{}
		err := rows.Scan(
			&album.ID, &album.Title, &album.Description, &album.CoverImageID,
			&album.CoverImagePath, &album.CoverThumbnailPath, &album.Status,
			&album.UserID, &album.CreatedAt, &album.UpdatedAt, &album.Metadata,
			&album.IsPublic, &album.ViewCount, &album.LikeCount, &album.Tags,
		)
		if err != nil {
			r.logger.WithError(err).Error("Failed to scan album row")
			continue
		}

		// Get image count
		album.ImageCount = r.getImageCount(album.ID)
		albums = append(albums, album)
	}

	return albums, nil
}

// GetAlbumCount returns the total number of albums
func (r *AlbumRepository) GetAlbumCount(userID *string) (int, error) {
	query := `SELECT COUNT(*) FROM albums`
	args := []interface{}{}
	
	if userID != nil {
		query += " WHERE user_id = $1"
		args = append(args, *userID)
	}

	var count int
	err := r.db.QueryRow(query, args...).Scan(&count)
	if err != nil {
		r.logger.WithError(err).Error("Failed to get album count")
		return 0, fmt.Errorf("failed to get album count: %w", err)
	}

	return count, nil
}
