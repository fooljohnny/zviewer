package middleware

import (
	"context"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

const (
	// RequestIDKey is the key for request ID in context
	RequestIDKey = "request_id"
	// UserIDKey is the key for user ID in context
	UserIDKey = "user_id"
)

// TracingMiddleware adds request tracing with correlation IDs
func TracingMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Generate request ID
		requestID := uuid.New().String()

		// Set request ID in context
		c.Set(RequestIDKey, requestID)

		// Add request ID to response headers
		c.Header("X-Request-ID", requestID)

		// Create context with request ID
		ctx := context.WithValue(c.Request.Context(), RequestIDKey, requestID)
		c.Request = c.Request.WithContext(ctx)

		// Log request start
		start := time.Now()
		logrus.WithFields(logrus.Fields{
			"request_id":  requestID,
			"method":      c.Request.Method,
			"path":        c.Request.URL.Path,
			"remote_addr": c.ClientIP(),
			"user_agent":  c.Request.UserAgent(),
		}).Info("Request started")

		// Process request
		c.Next()

		// Log request completion
		duration := time.Since(start)
		status := c.Writer.Status()

		logrus.WithFields(logrus.Fields{
			"request_id": requestID,
			"method":     c.Request.Method,
			"path":       c.Request.URL.Path,
			"status":     status,
			"duration":   duration,
			"size":       c.Writer.Size(),
		}).Info("Request completed")
	}
}

// GetRequestID extracts request ID from context
func GetRequestID(c *gin.Context) string {
	if requestID, exists := c.Get(RequestIDKey); exists {
		return requestID.(string)
	}
	return ""
}

// GetUserID extracts user ID from context
func GetUserID(c *gin.Context) string {
	if userID, exists := c.Get(UserIDKey); exists {
		return userID.(string)
	}
	return ""
}

// LogWithContext creates a logger with request context
func LogWithContext(c *gin.Context) *logrus.Entry {
	fields := logrus.Fields{
		"request_id": GetRequestID(c),
	}

	if userID := GetUserID(c); userID != "" {
		fields["user_id"] = userID
	}

	return logrus.WithFields(fields)
}
