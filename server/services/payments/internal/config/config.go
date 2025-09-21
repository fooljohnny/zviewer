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
	StripeSecretKey     string
	StripeWebhookSecret string
	StripePublishableKey string
	MaxPaymentAmount    int64
	MinPaymentAmount    int64
	SupportedCurrencies []string
	PaymentRateLimit    int
	RateLimitWindow     time.Duration
	EnableAuditLogging  bool
	LogLevel            string
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists
	if err := godotenv.Load(); err != nil {
		logrus.Warn("No .env file found, using environment variables")
	}

	config := &Config{
		Port:                getEnv("PORT", "8083"),
		DatabaseURL:         getEnv("DATABASE_URL", "postgres://user:password@localhost:5432/zviewer?sslmode=disable"),
		JWTSecret:           getEnv("JWT_SECRET", "your-secret-key"),
		StripeSecretKey:     getEnv("STRIPE_SECRET_KEY", ""),
		StripeWebhookSecret: getEnv("STRIPE_WEBHOOK_SECRET", ""),
		StripePublishableKey: getEnv("STRIPE_PUBLISHABLE_KEY", ""),
		MaxPaymentAmount:    getEnvAsInt64("MAX_PAYMENT_AMOUNT", 100000), // $1000.00 in cents
		MinPaymentAmount:    getEnvAsInt64("MIN_PAYMENT_AMOUNT", 50),     // $0.50 in cents
		SupportedCurrencies: []string{"USD", "EUR", "GBP", "CAD"},
		PaymentRateLimit:    getEnvAsInt("PAYMENT_RATE_LIMIT", 5),
		RateLimitWindow:     time.Duration(getEnvAsInt("RATE_LIMIT_WINDOW_MINUTES", 1)) * time.Minute,
		EnableAuditLogging:  getEnvAsBool("ENABLE_AUDIT_LOGGING", true),
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

// getEnvAsInt64 gets an environment variable as int64 with a default value
func getEnvAsInt64(key string, defaultValue int64) int64 {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.ParseInt(value, 10, 64); err == nil {
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
