package config

import (
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
	"github.com/sirupsen/logrus"
)

// Config holds all configuration for the admin service
type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Services ServicesConfig
	Logging  LoggingConfig
}

// ServerConfig holds server configuration
type ServerConfig struct {
	Port         string
	Host         string
	ReadTimeout  time.Duration
	WriteTimeout time.Duration
}

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
	SSLMode  string
}

// JWTConfig holds JWT configuration
type JWTConfig struct {
	SecretKey string
	Issuer    string
	ExpiresIn time.Duration
}

// ServicesConfig holds external services configuration
type ServicesConfig struct {
	UserServiceURL     string
	MediaServiceURL    string
	CommentsServiceURL string
	PaymentServiceURL  string
}

// LoggingConfig holds logging configuration
type LoggingConfig struct {
	Level  string
	Format string
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists
	if err := godotenv.Load(); err != nil {
		logrus.Warn("No .env file found, using environment variables")
	}

	config := &Config{
		Server: ServerConfig{
			Port:         getEnv("ADMIN_PORT", "8084"),
			Host:         getEnv("ADMIN_HOST", "0.0.0.0"),
			ReadTimeout:  getDurationEnv("ADMIN_READ_TIMEOUT", 30*time.Second),
			WriteTimeout: getDurationEnv("ADMIN_WRITE_TIMEOUT", 30*time.Second),
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
			User:     getEnv("DB_USER", "zviewer"),
			Password: getEnv("DB_PASSWORD", "password"),
			DBName:   getEnv("DB_NAME", "zviewer"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
		},
		JWT: JWTConfig{
			SecretKey: getEnv("JWT_SECRET", "your-secret-key"),
			Issuer:    getEnv("JWT_ISSUER", "zviewer-admin"),
			ExpiresIn: getDurationEnv("JWT_EXPIRES_IN", 24*time.Hour),
		},
		Services: ServicesConfig{
			UserServiceURL:     getEnv("USER_SERVICE_URL", "http://localhost:8081"),
			MediaServiceURL:    getEnv("MEDIA_SERVICE_URL", "http://localhost:8082"),
			CommentsServiceURL: getEnv("COMMENTS_SERVICE_URL", "http://localhost:8083"),
			PaymentServiceURL:  getEnv("PAYMENT_SERVICE_URL", "http://localhost:8085"),
		},
		Logging: LoggingConfig{
			Level:  getEnv("LOG_LEVEL", "info"),
			Format: getEnv("LOG_FORMAT", "json"),
		},
	}

	return config, nil
}

// getEnv gets an environment variable with a fallback value
func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

// getDurationEnv gets a duration environment variable with a fallback value
func getDurationEnv(key string, fallback time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return fallback
}

// getIntEnv gets an integer environment variable with a fallback value
func getIntEnv(key string, fallback int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return fallback
}
