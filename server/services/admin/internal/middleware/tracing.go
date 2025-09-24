package middleware

import (
	"context"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

const (
	TraceIDKey   = "trace_id"
	StartTimeKey = "start_time"
)

// Tracing middleware adds request tracing
func Tracing() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Generate trace ID
		traceID := uuid.New().String()

		// Set trace ID in context
		c.Set(TraceIDKey, traceID)
		c.Set(StartTimeKey, time.Now())

		// Add trace ID to response headers
		c.Header("X-Trace-ID", traceID)

		// Create logger with trace ID
		logger := logrus.WithFields(logrus.Fields{
			"trace_id": traceID,
			"method":   c.Request.Method,
			"path":     c.Request.URL.Path,
			"ip":       c.ClientIP(),
		})

		// Set logger in context
		c.Set("logger", logger)

		// Log request start
		logger.Info("Request started")

		// Process request
		c.Next()

		// Log request completion
		startTime, _ := c.Get(StartTimeKey)
		duration := time.Since(startTime.(time.Time))

		logger.WithFields(logrus.Fields{
			"status_code": c.Writer.Status(),
			"duration_ms": duration.Milliseconds(),
		}).Info("Request completed")
	}
}

// GetTraceID extracts trace ID from context
func GetTraceID(c *gin.Context) string {
	if traceID, exists := c.Get(TraceIDKey); exists {
		if id, ok := traceID.(string); ok {
			return id
		}
	}
	return ""
}

// GetLogger extracts logger from context
func GetLogger(c *gin.Context) *logrus.Entry {
	if logger, exists := c.Get("logger"); exists {
		if entry, ok := logger.(*logrus.Entry); ok {
			return entry
		}
	}
	return logrus.NewEntry(logrus.StandardLogger())
}

// WithTraceID adds trace ID to a context
func WithTraceID(ctx context.Context, traceID string) context.Context {
	return context.WithValue(ctx, TraceIDKey, traceID)
}

// GetTraceIDFromContext extracts trace ID from context
func GetTraceIDFromContext(ctx context.Context) string {
	if traceID, ok := ctx.Value(TraceIDKey).(string); ok {
		return traceID
	}
	return ""
}
