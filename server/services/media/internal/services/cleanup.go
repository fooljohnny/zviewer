package services

import (
	"context"
	"fmt"
	"time"

	"zviewer-media-service/internal/repositories"
	"zviewer-media-service/internal/storage"

	"github.com/sirupsen/logrus"
)

// CleanupService handles file cleanup and garbage collection
type CleanupService struct {
	mediaRepo *repositories.MediaRepository
	storage   storage.Storage
}

// NewCleanupService creates a new cleanup service
func NewCleanupService(mediaRepo *repositories.MediaRepository, storage storage.Storage) *CleanupService {
	return &CleanupService{
		mediaRepo: mediaRepo,
		storage:   storage,
	}
}

// CleanupOrphanedFiles removes files that are not referenced in the database
func (cs *CleanupService) CleanupOrphanedFiles(ctx context.Context) error {
	logrus.Info("Starting orphaned files cleanup")

	// Get all file paths from database
	dbFiles, err := cs.getDatabaseFilePaths(ctx)
	if err != nil {
		return fmt.Errorf("failed to get database file paths: %w", err)
	}

	// Create a map for quick lookup
	dbFileMap := make(map[string]bool)
	for _, filePath := range dbFiles {
		dbFileMap[filePath] = true
	}

	// TODO: Implement storage-specific file listing
	// This would require adding a ListFiles method to the Storage interface
	// For now, we'll skip this implementation

	logrus.Info("Orphaned files cleanup completed")
	return nil
}

// CleanupOldFiles removes files older than the specified retention period
func (cs *CleanupService) CleanupOldFiles(ctx context.Context, retentionDays int) error {
	logrus.Infof("Starting old files cleanup (retention: %d days)", retentionDays)

	cutoffDate := time.Now().AddDate(0, 0, -retentionDays)

	// Get old media items
	oldMedia, err := cs.getOldMediaItems(ctx, cutoffDate)
	if err != nil {
		return fmt.Errorf("failed to get old media items: %w", err)
	}

	// Delete files and database records
	for _, media := range oldMedia {
		// Delete file from storage
		if err := cs.storage.DeleteFile(ctx, media.FilePath); err != nil {
			logrus.Warnf("Failed to delete file %s: %v", media.FilePath, err)
		}

		// Delete thumbnail if exists
		if media.ThumbnailPath != nil {
			if err := cs.storage.DeleteFile(ctx, *media.ThumbnailPath); err != nil {
				logrus.Warnf("Failed to delete thumbnail %s: %v", *media.ThumbnailPath, err)
			}
		}

		// Delete from database
		if err := cs.mediaRepo.Delete(media.ID); err != nil {
			logrus.Errorf("Failed to delete media record %s: %v", media.ID, err)
		}

		logrus.Infof("Deleted old media: %s", media.ID)
	}

	logrus.Infof("Old files cleanup completed, deleted %d items", len(oldMedia))
	return nil
}

// ValidateFileIntegrity checks file integrity and removes corrupted files
func (cs *CleanupService) ValidateFileIntegrity(ctx context.Context) error {
	logrus.Info("Starting file integrity validation")

	// Get all media items
	allMedia, err := cs.getAllMediaItems(ctx)
	if err != nil {
		return fmt.Errorf("failed to get all media items: %w", err)
	}

	corruptedCount := 0
	for _, media := range allMedia {
		// Check if file exists
		exists, err := cs.storage.FileExists(ctx, media.FilePath)
		if err != nil {
			logrus.Errorf("Failed to check file existence for %s: %v", media.FilePath, err)
			continue
		}

		if !exists {
			logrus.Warnf("File not found: %s", media.FilePath)
			corruptedCount++
			continue
		}

		// Check file size matches database record
		actualSize, err := cs.storage.GetFileSize(ctx, media.FilePath)
		if err != nil {
			logrus.Errorf("Failed to get file size for %s: %v", media.FilePath, err)
			continue
		}

		if actualSize != media.FileSize {
			logrus.Warnf("File size mismatch for %s: expected %d, got %d",
				media.FilePath, media.FileSize, actualSize)
			corruptedCount++
		}
	}

	logrus.Infof("File integrity validation completed, found %d corrupted files", corruptedCount)
	return nil
}

// CleanupUserQuota removes files for users who exceed their quota
func (cs *CleanupService) CleanupUserQuota(ctx context.Context, maxQuotaBytes int64) error {
	logrus.Info("Starting user quota cleanup")

	// Get user file usage
	userUsage, err := cs.getUserFileUsage(ctx)
	if err != nil {
		return fmt.Errorf("failed to get user file usage: %w", err)
	}

	// Find users exceeding quota
	for userID, usage := range userUsage {
		if usage > maxQuotaBytes {
			logrus.Infof("User %s exceeds quota: %d bytes", userID, usage)

			// Get user's oldest files
			oldFiles, err := cs.getUserOldestFiles(ctx, userID)
			if err != nil {
				logrus.Errorf("Failed to get oldest files for user %s: %v", userID, err)
				continue
			}

			// Delete files until quota is met
			for _, media := range oldFiles {
				if usage <= maxQuotaBytes {
					break
				}

				// Delete file
				if err := cs.storage.DeleteFile(ctx, media.FilePath); err != nil {
					logrus.Warnf("Failed to delete file %s: %v", media.FilePath, err)
					continue
				}

				// Delete thumbnail
				if media.ThumbnailPath != nil {
					cs.storage.DeleteFile(ctx, *media.ThumbnailPath)
				}

				// Delete from database
				if err := cs.mediaRepo.Delete(media.ID); err != nil {
					logrus.Errorf("Failed to delete media record %s: %v", media.ID, err)
					continue
				}

				usage -= media.FileSize
				logrus.Infof("Deleted file %s for quota cleanup", media.ID)
			}
		}
	}

	logrus.Info("User quota cleanup completed")
	return nil
}

// getDatabaseFilePaths gets all file paths from the database
func (cs *CleanupService) getDatabaseFilePaths(ctx context.Context) ([]string, error) {
	// This would require adding a method to the repository
	// For now, return empty slice
	return []string{}, nil
}

// getOldMediaItems gets media items older than the cutoff date
func (cs *CleanupService) getOldMediaItems(ctx context.Context, cutoffDate time.Time) ([]MediaItem, error) {
	// This would require adding a method to the repository
	// For now, return empty slice
	return []MediaItem{}, nil
}

// getAllMediaItems gets all media items
func (cs *CleanupService) getAllMediaItems(ctx context.Context) ([]MediaItem, error) {
	// This would require adding a method to the repository
	// For now, return empty slice
	return []MediaItem{}, nil
}

// getUserFileUsage gets file usage per user
func (cs *CleanupService) getUserFileUsage(ctx context.Context) (map[string]int64, error) {
	// This would require adding a method to the repository
	// For now, return empty map
	return map[string]int64{}, nil
}

// getUserOldestFiles gets the oldest files for a user
func (cs *CleanupService) getUserOldestFiles(ctx context.Context, userID string) ([]MediaItem, error) {
	// This would require adding a method to the repository
	// For now, return empty slice
	return []MediaItem{}, nil
}

// MediaItem represents a media item for cleanup operations
type MediaItem struct {
	ID            string
	FilePath      string
	ThumbnailPath *string
	FileSize      int64
	UserID        string
	UploadedAt    time.Time
}
