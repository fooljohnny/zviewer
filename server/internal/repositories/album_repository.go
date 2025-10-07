package repositories

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"zviewer-server/internal/models"
	"zviewer-server/pkg/image"

	"github.com/google/uuid"
	"github.com/lib/pq"
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
	// Serialize metadata to JSON
	metadataJSON, err := json.Marshal(album.Metadata)
	if err != nil {
		r.logger.WithError(err).Error("Failed to marshal metadata")
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	// Convert tags to PostgreSQL array format
	// PostgreSQL expects array format like {"tag1","tag2","tag3"}
	// Use pq.Array to properly convert Go slice to PostgreSQL array
	tagsArray := pq.Array(album.Tags)

	query := `
		INSERT INTO albums (id, title, description, status, user_id, created_at, updated_at, 
		                   metadata, is_public, view_count, like_count, tags)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		RETURNING id, created_at, updated_at`

	args := []interface{}{
		album.ID, album.Title, album.Description, album.Status, album.UserID,
		album.CreatedAt, album.UpdatedAt, string(metadataJSON), album.IsPublic,
		album.ViewCount, album.LikeCount, tagsArray,
	}

	err = r.db.QueryRow(query, args...).Scan(&album.ID, &album.CreatedAt, &album.UpdatedAt)
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
	var metadataJSON []byte
	var tagsArray pq.StringArray
	err := r.db.QueryRow(query, id).Scan(
		&album.ID, &album.Title, &album.Description, &album.CoverImageID,
		&album.CoverImagePath, &album.CoverThumbnailPath, &album.Status,
		&album.UserID, &album.CreatedAt, &album.UpdatedAt, &metadataJSON,
		&album.IsPublic, &album.ViewCount, &album.LikeCount, &tagsArray,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("album not found")
		}
		r.logger.WithError(err).Error("Failed to get album by ID")
		return nil, fmt.Errorf("failed to get album: %w", err)
	}

	// Deserialize metadata from JSON
	if len(metadataJSON) > 0 {
		if err := json.Unmarshal(metadataJSON, &album.Metadata); err != nil {
			r.logger.WithError(err).Warn("Failed to unmarshal metadata, using empty map")
			album.Metadata = make(map[string]interface{})
		}
	} else {
		album.Metadata = make(map[string]interface{})
	}

	// Convert pq.StringArray to []string
	album.Tags = []string(tagsArray)

	// Get image count
	album.ImageCount = r.getImageCount(album.ID)

	// Set userName (for now, use userID as userName)
	album.UserName = album.UserID

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
		var metadataJSON []byte
		var tagsArray pq.StringArray
		err := rows.Scan(
			&album.ID, &album.Title, &album.Description, &album.CoverImageID,
			&album.CoverImagePath, &album.CoverThumbnailPath, &album.Status,
			&album.UserID, &album.CreatedAt, &album.UpdatedAt, &metadataJSON,
			&album.IsPublic, &album.ViewCount, &album.LikeCount, &tagsArray,
		)
		if err != nil {
			r.logger.WithError(err).Error("Failed to scan album row")
			continue
		}

		// Deserialize metadata from JSON
		if len(metadataJSON) > 0 {
			if err := json.Unmarshal(metadataJSON, &album.Metadata); err != nil {
				r.logger.WithError(err).Warn("Failed to unmarshal metadata, using empty map")
				album.Metadata = make(map[string]interface{})
			}
		} else {
			album.Metadata = make(map[string]interface{})
		}

		// Convert pq.StringArray to []string
		album.Tags = []string(tagsArray)

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
		var metadataJSON []byte
		var tagsArray pq.StringArray
		err := rows.Scan(
			&album.ID, &album.Title, &album.Description, &album.CoverImageID,
			&album.CoverImagePath, &album.CoverThumbnailPath, &album.Status,
			&album.UserID, &album.CreatedAt, &album.UpdatedAt, &metadataJSON,
			&album.IsPublic, &album.ViewCount, &album.LikeCount, &tagsArray,
		)
		if err != nil {
			r.logger.WithError(err).Error("Failed to scan album row")
			continue
		}

		// Deserialize metadata from JSON
		if len(metadataJSON) > 0 {
			if err := json.Unmarshal(metadataJSON, &album.Metadata); err != nil {
				r.logger.WithError(err).Warn("Failed to unmarshal metadata, using empty map")
				album.Metadata = make(map[string]interface{})
			}
		} else {
			album.Metadata = make(map[string]interface{})
		}

		// Convert pq.StringArray to []string
		album.Tags = []string(tagsArray)

		// Get image count
		album.ImageCount = r.getImageCount(album.ID)
		albums = append(albums, album)
	}

	return albums, nil
}

// Update updates an album
func (r *AlbumRepository) Update(album *models.Album) error {
	// Serialize metadata to JSON
	metadataJSON, err := json.Marshal(album.Metadata)
	if err != nil {
		r.logger.WithError(err).Error("Failed to marshal metadata")
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	// Convert tags to PostgreSQL array format
	tagsArray := pq.Array(album.Tags)

	query := `
		UPDATE albums 
		SET title = $2, description = $3, cover_image_id = $4, cover_image_path = $5,
		    cover_thumbnail_path = $6, status = $7, updated_at = $8, metadata = $9,
		    is_public = $10, view_count = $11, like_count = $12, tags = $13
		WHERE id = $1`

	_, err = r.db.Exec(query,
		album.ID, album.Title, album.Description, album.CoverImageID,
		album.CoverImagePath, album.CoverThumbnailPath, album.Status,
		album.UpdatedAt, string(metadataJSON), album.IsPublic,
		album.ViewCount, album.LikeCount, tagsArray,
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
	// Resolve the actual file path for dimension extraction
	// imagePath is like "/media/stream/{imageID}" but actual file is in services/media/uploads/media/...
	actualFilePath := r.resolveImageFilePath(imageID)

	// Get image dimensions
	// First check if file exists
	fileInfo, fileExistsErr := os.Stat(actualFilePath)
	fileExists := fileExistsErr == nil
	fileSize := int64(0)
	if fileExists {
		fileSize = fileInfo.Size()
	}

	r.logger.WithFields(logrus.Fields{
		"imageID":        imageID,
		"actualFilePath": actualFilePath,
		"fileExists":     fileExists,
		"fileSize":       fileSize,
		"fileError":      fileExistsErr,
	}).Debug("Attempting to get image dimensions")

	var width, height int
	var err error

	if !fileExists {
		r.logger.WithError(fileExistsErr).WithFields(logrus.Fields{
			"imageID":        imageID,
			"actualFilePath": actualFilePath,
			"errorType":      "FILE_NOT_FOUND",
		}).Error("Image file not found, cannot extract dimensions")
		// Use reasonable default values
		width, height = 1920, 1080
	} else {
		// File exists, try to get dimensions
		width, height, err = image.GetImageDimensions(actualFilePath)
		if err != nil {
			r.logger.WithError(err).WithFields(logrus.Fields{
				"imageID":        imageID,
				"actualFilePath": actualFilePath,
				"fileSize":       fileSize,
				"errorType":      "DIMENSION_EXTRACTION_FAILED",
			}).Error("Failed to extract image dimensions from existing file, using default values")
			// Use reasonable default values that won't cause aspect ratio issues
			width, height = 1920, 1080
		} else {
			r.logger.WithFields(logrus.Fields{
				"imageID":        imageID,
				"actualFilePath": actualFilePath,
				"width":          width,
				"height":         height,
				"aspectRatio":    float64(width) / float64(height),
				"fileSize":       fileSize,
			}).Info("Successfully extracted image dimensions")
		}
	}

	query := `
		INSERT INTO album_images (id, album_id, image_id, image_path, width, height, sort_order, added_by, added_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`

	_, err = r.db.Exec(query, uuid.New().String(), albumID, imageID, imagePath, width, height, sortOrder, addedBy, time.Now())
	if err != nil {
		r.logger.WithError(err).Error("Failed to add image to album")
		return fmt.Errorf("failed to add image to album: %w", err)
	}

	r.logger.WithFields(logrus.Fields{
		"albumID":   albumID,
		"imageID":   imageID,
		"imagePath": imagePath,
		"width":     width,
		"height":    height,
	}).Info("Successfully added image to album with dimensions")

	return nil
}

// resolveImageFilePath resolves the actual file path for an image ID
func (r *AlbumRepository) resolveImageFilePath(imageID string) string {
	// The actual file structure is: services/media/uploads/media/YYYY/MM/DD/userID/imageID.ext
	// We need to find the file by searching through the directory structure
	basePath := "services/media/uploads/media"

	r.logger.WithFields(logrus.Fields{
		"imageID":  imageID,
		"basePath": basePath,
	}).Debug("Starting image file path resolution")

	// Get current year, month, day
	now := time.Now()
	year := now.Format("2006")
	month := now.Format("01")
	day := now.Format("02")

	r.logger.WithFields(logrus.Fields{
		"imageID": imageID,
		"year":    year,
		"month":   month,
		"day":     day,
	}).Debug("Generated date components for path resolution")

	// Try current date first
	possiblePaths := []string{
		fmt.Sprintf("%s/%s/%s/%s/%s.jpg", basePath, year, month, day, imageID),
		fmt.Sprintf("%s/%s/%s/%s/%s.jpeg", basePath, year, month, day, imageID),
		fmt.Sprintf("%s/%s/%s/%s/%s.png", basePath, year, month, day, imageID),
		fmt.Sprintf("%s/%s/%s/00000000-0000-0000-0000-000000000000/%s.jpg", basePath, year, month, imageID),
		fmt.Sprintf("%s/%s/%s/00000000-0000-0000-0000-000000000000/%s.jpeg", basePath, year, month, imageID),
		fmt.Sprintf("%s/%s/%s/00000000-0000-0000-0000-000000000000/%s.png", basePath, year, month, imageID),
	}

	r.logger.WithFields(logrus.Fields{
		"imageID":      imageID,
		"currentPaths": possiblePaths,
		"pathCount":    len(possiblePaths),
	}).Debug("Generated current date paths")

	// Try previous days (up to 30 days back) - increased from 7 to 30
	for i := 1; i <= 30; i++ {
		prevDay := now.AddDate(0, 0, -i)
		prevYear := prevDay.Format("2006")
		prevMonth := prevDay.Format("01")
		prevDayStr := prevDay.Format("02")

		dayPaths := []string{
			fmt.Sprintf("%s/%s/%s/%s/%s.jpg", basePath, prevYear, prevMonth, prevDayStr, imageID),
			fmt.Sprintf("%s/%s/%s/%s/%s.jpeg", basePath, prevYear, prevMonth, prevDayStr, imageID),
			fmt.Sprintf("%s/%s/%s/%s/%s.png", basePath, prevYear, prevMonth, prevDayStr, imageID),
			fmt.Sprintf("%s/%s/%s/00000000-0000-0000-0000-000000000000/%s.jpg", basePath, prevYear, prevMonth, imageID),
			fmt.Sprintf("%s/%s/%s/00000000-0000-0000-0000-000000000000/%s.jpeg", basePath, prevYear, prevMonth, imageID),
			fmt.Sprintf("%s/%s/%s/00000000-0000-0000-0000-000000000000/%s.png", basePath, prevYear, prevMonth, imageID),
		}
		possiblePaths = append(possiblePaths, dayPaths...)

		// Log every 5 days to avoid too much logging
		if i%5 == 0 {
			r.logger.WithFields(logrus.Fields{
				"imageID":   imageID,
				"daysBack":  i,
				"prevYear":  prevYear,
				"prevMonth": prevMonth,
				"prevDay":   prevDayStr,
				"dayPaths":  dayPaths,
			}).Debug("Generated paths for previous day")
		}
	}

	r.logger.WithFields(logrus.Fields{
		"imageID":    imageID,
		"totalPaths": len(possiblePaths),
		"searchDays": 30,
	}).Debug("Generated all possible paths, starting file existence check")

	// Also try searching in all subdirectories recursively as a fallback
	r.logger.WithFields(logrus.Fields{
		"imageID":  imageID,
		"basePath": basePath,
	}).Debug("Starting recursive search as fallback")

	recursivePaths := r.findImageFileRecursively(basePath, imageID)
	possiblePaths = append(possiblePaths, recursivePaths...)

	r.logger.WithFields(logrus.Fields{
		"imageID":        imageID,
		"recursivePaths": recursivePaths,
		"recursiveCount": len(recursivePaths),
		"totalPaths":     len(possiblePaths),
	}).Debug("Completed recursive search")

	// Check if any of the possible paths exist
	foundPaths := []string{}
	for i, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			foundPaths = append(foundPaths, path)
			r.logger.WithFields(logrus.Fields{
				"imageID":    imageID,
				"foundPath":  path,
				"pathIndex":  i,
				"totalPaths": len(possiblePaths),
			}).Info("Found image file")
			return path
		}
	}

	// If no file found, return the first possible path (will fail gracefully)
	r.logger.WithFields(logrus.Fields{
		"imageID":    imageID,
		"totalPaths": len(possiblePaths),
		"foundPaths": foundPaths,
		"firstPath":  possiblePaths[0],
		"basePath":   basePath,
		"basePathExists": func() bool {
			if _, err := os.Stat(basePath); err == nil {
				return true
			}
			return false
		}(),
	}).Warn("Could not find image file in any expected location, using first possible path")
	return possiblePaths[0]
}

// findImageFileRecursively searches for an image file recursively in the base directory
func (r *AlbumRepository) findImageFileRecursively(basePath, imageID string) []string {
	var paths []string

	r.logger.WithFields(logrus.Fields{
		"imageID":  imageID,
		"basePath": basePath,
	}).Debug("Starting recursive file search")

	// Define supported extensions
	extensions := []string{"jpg", "jpeg", "png", "gif", "webp"}

	// Check if base path exists
	if _, err := os.Stat(basePath); err != nil {
		r.logger.WithError(err).WithFields(logrus.Fields{
			"imageID":  imageID,
			"basePath": basePath,
		}).Warn("Base path does not exist for recursive search")
		return paths
	}

	// Walk through the directory tree
	fileCount := 0
	matchedFiles := 0

	err := filepath.Walk(basePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			r.logger.WithError(err).WithFields(logrus.Fields{
				"imageID": imageID,
				"path":    path,
			}).Debug("Error accessing path during recursive search")
			return nil // Continue walking even if there's an error
		}

		// Check if this is a file and matches our image ID
		if !info.IsDir() {
			fileCount++
			fileName := filepath.Base(path)
			ext := filepath.Ext(fileName)
			if ext != "" {
				ext = ext[1:] // Remove the dot
				nameWithoutExt := strings.TrimSuffix(fileName, "."+ext)

				// Check if the file name (without extension) matches the image ID
				if nameWithoutExt == imageID {
					matchedFiles++
					// Check if the extension is supported
					for _, supportedExt := range extensions {
						if ext == supportedExt {
							paths = append(paths, path)
							r.logger.WithFields(logrus.Fields{
								"imageID":   imageID,
								"foundPath": path,
								"fileName":  fileName,
								"extension": ext,
								"fileSize":  info.Size(),
							}).Debug("Found matching file during recursive search")
							break
						}
					}
				}
			}
		}

		return nil
	})

	if err != nil {
		r.logger.WithError(err).WithFields(logrus.Fields{
			"imageID":  imageID,
			"basePath": basePath,
		}).Error("Error walking directory tree during recursive search")
	}

	r.logger.WithFields(logrus.Fields{
		"imageID":      imageID,
		"basePath":     basePath,
		"filesScanned": fileCount,
		"matchedFiles": matchedFiles,
		"foundPaths":   paths,
		"pathCount":    len(paths),
	}).Debug("Completed recursive file search")

	return paths
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
