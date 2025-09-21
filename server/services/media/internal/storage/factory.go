package storage

import (
	"fmt"
	"zviewer-media-service/internal/config"
)

// StorageFactory creates storage instances based on configuration
type StorageFactory struct{}

// NewStorageFactory creates a new storage factory
func NewStorageFactory() *StorageFactory {
	return &StorageFactory{}
}

// CreateStorage creates a storage instance based on the configuration
func (sf *StorageFactory) CreateStorage(cfg *config.Config) (Storage, error) {
	switch cfg.StorageType {
	case "local":
		return NewLocalStorage(cfg.LocalStoragePath), nil
	case "s3":
		if !cfg.IsS3Storage() {
			return nil, fmt.Errorf("S3 storage not properly configured")
		}
		return NewS3Storage(cfg.S3Bucket, cfg.S3Region, cfg.S3AccessKey, cfg.S3SecretKey)
	default:
		return nil, fmt.Errorf("unsupported storage type: %s", cfg.StorageType)
	}
}
