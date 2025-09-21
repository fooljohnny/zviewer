package storage

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// LocalStorage implements the Storage interface for local file system
type LocalStorage struct {
	basePath string
}

// NewLocalStorage creates a new local storage instance
func NewLocalStorage(basePath string) *LocalStorage {
	return &LocalStorage{
		basePath: basePath,
	}
}

// SaveFile saves a file to local storage
func (ls *LocalStorage) SaveFile(ctx context.Context, filePath string, reader io.Reader) error {
	// Ensure the directory exists
	fullPath := filepath.Join(ls.basePath, filePath)
	dir := filepath.Dir(fullPath)
	
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory %s: %w", dir, err)
	}

	// Create the file
	file, err := os.Create(fullPath)
	if err != nil {
		return fmt.Errorf("failed to create file %s: %w", fullPath, err)
	}
	defer file.Close()

	// Copy the content
	_, err = io.Copy(file, reader)
	if err != nil {
		// Clean up the file if copy fails
		os.Remove(fullPath)
		return fmt.Errorf("failed to copy file content: %w", err)
	}

	return nil
}

// SaveFileFromBytes saves a file from byte data to local storage
func (ls *LocalStorage) SaveFileFromBytes(ctx context.Context, filePath string, data []byte) error {
	// Ensure the directory exists
	fullPath := filepath.Join(ls.basePath, filePath)
	dir := filepath.Dir(fullPath)
	
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory %s: %w", dir, err)
	}

	// Create the file
	file, err := os.Create(fullPath)
	if err != nil {
		return fmt.Errorf("failed to create file %s: %w", fullPath, err)
	}
	defer file.Close()

	// Write the data
	_, err = file.Write(data)
	if err != nil {
		// Clean up the file if write fails
		os.Remove(fullPath)
		return fmt.Errorf("failed to write file content: %w", err)
	}

	return nil
}

// GetFile retrieves a file from local storage
func (ls *LocalStorage) GetFile(ctx context.Context, filePath string) (io.ReadCloser, error) {
	fullPath := filepath.Join(ls.basePath, filePath)
	
	file, err := os.Open(fullPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, fmt.Errorf("file not found: %s", filePath)
		}
		return nil, fmt.Errorf("failed to open file %s: %w", filePath, err)
	}

	return file, nil
}

// DeleteFile removes a file from local storage
func (ls *LocalStorage) DeleteFile(ctx context.Context, filePath string) error {
	fullPath := filepath.Join(ls.basePath, filePath)
	
	err := os.Remove(fullPath)
	if err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to delete file %s: %w", filePath, err)
	}

	return nil
}

// FileExists checks if a file exists in local storage
func (ls *LocalStorage) FileExists(ctx context.Context, filePath string) (bool, error) {
	fullPath := filepath.Join(ls.basePath, filePath)
	
	_, err := os.Stat(fullPath)
	if err != nil {
		if os.IsNotExist(err) {
			return false, nil
		}
		return false, fmt.Errorf("failed to check file existence: %w", err)
	}

	return true, nil
}

// GetFileSize returns the size of a file in local storage
func (ls *LocalStorage) GetFileSize(ctx context.Context, filePath string) (int64, error) {
	fullPath := filepath.Join(ls.basePath, filePath)
	
	stat, err := os.Stat(fullPath)
	if err != nil {
		if os.IsNotExist(err) {
			return 0, fmt.Errorf("file not found: %s", filePath)
		}
		return 0, fmt.Errorf("failed to get file size: %w", err)
	}

	return stat.Size(), nil
}

// GetFileURL returns a URL for accessing the file
func (ls *LocalStorage) GetFileURL(ctx context.Context, filePath string) (string, error) {
	// For local storage, we return a relative path that can be served by the web server
	// In production, this would typically be a full URL
	return "/media/" + strings.ReplaceAll(filePath, "\\", "/"), nil
}
