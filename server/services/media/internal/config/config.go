package config

import (
	"os"
	"strconv"
	"strings"

	"github.com/joho/godotenv"
)

// Config holds the configuration for the media service
type Config struct {
	Port        string
	DatabaseURL string
	JWTSecret   string

	// Storage configuration
	StorageType      string // "local" or "s3"
	LocalStoragePath string
	S3Bucket         string
	S3Region         string
	S3AccessKey      string
	S3SecretKey      string

	// File limits
	MaxImageSize int64 // in bytes
	MaxVideoSize int64 // in bytes

	// Processing configuration
	ImageThumbnailSize int
	VideoThumbnailSize int
	VideoThumbnailTime int // seconds into video

	// Upload limits
	MaxConcurrentUploads int
	UploadTimeout        int // minutes
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists
	_ = godotenv.Load()

	cfg := &Config{
		Port:        getEnv("PORT", "8081"),
		DatabaseURL: getEnv("DATABASE_URL", "postgres://zviewer:zviewer123@localhost:5432/zviewer?sslmode=disable"),
		JWTSecret:   getEnv("JWT_SECRET", "your-secret-key"),

		// Storage configuration
		StorageType:      getEnv("STORAGE_TYPE", "local"),
		LocalStoragePath: getEnv("LOCAL_STORAGE_PATH", "./uploads/media"),
		S3Bucket:         getEnv("S3_BUCKET", ""),
		S3Region:         getEnv("S3_REGION", "us-east-1"),
		S3AccessKey:      getEnv("S3_ACCESS_KEY", ""),
		S3SecretKey:      getEnv("S3_SECRET_KEY", ""),

		// File limits (100MB for images, 500MB for videos)
		MaxImageSize: getEnvAsInt64("MAX_IMAGE_SIZE", 100*1024*1024),
		MaxVideoSize: getEnvAsInt64("MAX_VIDEO_SIZE", 500*1024*1024),

		// Processing configuration
		ImageThumbnailSize: getEnvAsInt("IMAGE_THUMBNAIL_SIZE", 300),
		VideoThumbnailSize: getEnvAsInt("VIDEO_THUMBNAIL_SIZE", 320),
		VideoThumbnailTime: getEnvAsInt("VIDEO_THUMBNAIL_TIME", 10),

		// Upload limits
		MaxConcurrentUploads: getEnvAsInt("MAX_CONCURRENT_UPLOADS", 10),
		UploadTimeout:        getEnvAsInt("UPLOAD_TIMEOUT", 30),
	}

	return cfg, nil
}

// getEnv gets an environment variable with a fallback value
func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

// getEnvAsInt gets an environment variable as integer with a fallback value
func getEnvAsInt(key string, fallback int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return fallback
}

// getEnvAsInt64 gets an environment variable as int64 with a fallback value
func getEnvAsInt64(key string, fallback int64) int64 {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.ParseInt(value, 10, 64); err == nil {
			return intValue
		}
	}
	return fallback
}

// IsS3Storage returns true if S3 storage is configured
func (c *Config) IsS3Storage() bool {
	return strings.ToLower(c.StorageType) == "s3" && c.S3Bucket != ""
}
