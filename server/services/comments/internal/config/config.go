package config

import (
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
	"github.com/sirupsen/logrus"
)

// Config holds the application configuration
type Config struct {
	Port                string
	DatabaseURL         string
	JWTSecret           string
	MaxCommentLength    int
	MaxRepliesPerComment int
	CommentRateLimit    int
	RateLimitWindow     time.Duration
	EnableProfanityFilter bool
	EnableModeration    bool
	LogLevel            string
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists
	if err := godotenv.Load(); err != nil {
		logrus.Warn("No .env file found, using environment variables")
	}

	config := &Config{
		Port:                getEnv("PORT", "8082"),
		DatabaseURL:         getEnv("DATABASE_URL", "postgres://user:password@localhost:5432/zviewer?sslmode=disable"),
		JWTSecret:           getEnv("JWT_SECRET", "your-secret-key"),
		MaxCommentLength:    getEnvAsInt("MAX_COMMENT_LENGTH", 1000),
		MaxRepliesPerComment: getEnvAsInt("MAX_REPLIES_PER_COMMENT", 50),
		CommentRateLimit:    getEnvAsInt("COMMENT_RATE_LIMIT", 10),
		RateLimitWindow:     time.Duration(getEnvAsInt("RATE_LIMIT_WINDOW_MINUTES", 1)) * time.Minute,
		EnableProfanityFilter: getEnvAsBool("ENABLE_PROFANITY_FILTER", true),
		EnableModeration:    getEnvAsBool("ENABLE_MODERATION", true),
		LogLevel:           getEnv("LOG_LEVEL", "info"),
	}

	return config, nil
}

// getEnv gets an environment variable with a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvAsInt gets an environment variable as integer with a default value
func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

// getEnvAsBool gets an environment variable as boolean with a default value
func getEnvAsBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return defaultValue
}
