package storage

import (
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

// PathGenerator handles file path generation for media files
type PathGenerator struct{}

// NewPathGenerator creates a new path generator
func NewPathGenerator() *PathGenerator {
	return &PathGenerator{}
}

// GeneratePath generates a file path following the pattern: {year}/{month}/{day}/{user_id}/{file_id}.{ext}
func (pg *PathGenerator) GeneratePath(userID, originalFilename string) (string, string, error) {
	// Generate a unique file ID
	fileID := uuid.New().String()
	
	// Get current time
	now := time.Now()
	year := now.Format("2006")
	month := now.Format("01")
	day := now.Format("02")
	
	// Extract file extension
	ext := strings.ToLower(filepath.Ext(originalFilename))
	if ext == "" {
		return "", "", fmt.Errorf("file must have an extension")
	}
	
	// Remove the dot from extension
	ext = ext[1:]
	
	// Generate the path
	path := fmt.Sprintf("%s/%s/%s/%s/%s.%s", year, month, day, userID, fileID, ext)
	
	return path, fileID, nil
}

// GenerateThumbnailPath generates a thumbnail path for a given file path
func (pg *PathGenerator) GenerateThumbnailPath(filePath string) string {
	ext := filepath.Ext(filePath)
	basePath := strings.TrimSuffix(filePath, ext)
	return basePath + "_thumb" + ext
}

// ValidatePath validates that a file path is safe and follows expected patterns
func (pg *PathGenerator) ValidatePath(path string) error {
	// Check for directory traversal attempts
	if strings.Contains(path, "..") {
		return fmt.Errorf("invalid path: contains directory traversal")
	}
	
	// Check for absolute paths
	if filepath.IsAbs(path) {
		return fmt.Errorf("invalid path: must be relative")
	}
	
	// Check for empty path
	if strings.TrimSpace(path) == "" {
		return fmt.Errorf("invalid path: cannot be empty")
	}
	
	return nil
}
