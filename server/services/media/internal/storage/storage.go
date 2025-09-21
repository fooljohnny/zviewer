package storage

import (
	"context"
	"io"
)

// Storage interface defines the contract for file storage backends
type Storage interface {
	// SaveFile saves a file to storage and returns the file path
	SaveFile(ctx context.Context, filePath string, reader io.Reader) error
	
	// SaveFileFromBytes saves a file from byte data to storage
	SaveFileFromBytes(ctx context.Context, filePath string, data []byte) error
	
	// GetFile retrieves a file from storage
	GetFile(ctx context.Context, filePath string) (io.ReadCloser, error)
	
	// DeleteFile removes a file from storage
	DeleteFile(ctx context.Context, filePath string) error
	
	// FileExists checks if a file exists in storage
	FileExists(ctx context.Context, filePath string) (bool, error)
	
	// GetFileSize returns the size of a file in storage
	GetFileSize(ctx context.Context, filePath string) (int64, error)
	
	// GetFileURL returns a URL for accessing the file (for S3, CDN, etc.)
	GetFileURL(ctx context.Context, filePath string) (string, error)
}

// FileInfo contains metadata about a stored file
type FileInfo struct {
	Path     string
	Size     int64
	MimeType string
	URL      string
}
