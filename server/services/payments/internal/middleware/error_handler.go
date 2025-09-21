package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// ErrorResponse represents a standardized error response
type ErrorResponse struct {
	Error   string `json:"error"`
	Details string `json:"details,omitempty"`
	Code    string `json:"code,omitempty"`
}

// ErrorHandler provides standardized error handling
func ErrorHandler() gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		if err, ok := recovered.(string); ok {
			LogWithContext(c).WithField("panic", err).Error("Panic recovered")
			c.JSON(http.StatusInternalServerError, ErrorResponse{
				Error:   "Internal server error",
				Details: "An unexpected error occurred",
			})
		} else {
			LogWithContext(c).WithField("panic", recovered).Error("Panic recovered")
			c.JSON(http.StatusInternalServerError, ErrorResponse{
				Error:   "Internal server error",
				Details: "An unexpected error occurred",
			})
		}
		c.Abort()
	})
}

// HandleError handles errors consistently across handlers
func HandleError(c *gin.Context, err error, statusCode int, message string) {
	LogWithContext(c).WithError(err).Error(message)
	
	response := ErrorResponse{
		Error: message,
	}
	
	// Add details in development mode
	if gin.Mode() == gin.DebugMode {
		response.Details = err.Error()
	}
	
	c.JSON(statusCode, response)
}

// HandleValidationError handles validation errors
func HandleValidationError(c *gin.Context, err error) {
	HandleError(c, err, http.StatusBadRequest, "Validation failed")
}

// HandleNotFoundError handles not found errors
func HandleNotFoundError(c *gin.Context, resource string) {
	LogWithContext(c).WithField("resource", resource).Warn("Resource not found")
	c.JSON(http.StatusNotFound, ErrorResponse{
		Error:   "Resource not found",
		Details: resource + " not found",
	})
}

// HandleUnauthorizedError handles unauthorized errors
func HandleUnauthorizedError(c *gin.Context, message string) {
	LogWithContext(c).Warn("Unauthorized access attempt")
	c.JSON(http.StatusUnauthorized, ErrorResponse{
		Error:   "Unauthorized",
		Details: message,
	})
}

// HandleForbiddenError handles forbidden errors
func HandleForbiddenError(c *gin.Context, message string) {
	LogWithContext(c).Warn("Forbidden access attempt")
	c.JSON(http.StatusForbidden, ErrorResponse{
		Error:   "Access denied",
		Details: message,
	})
}

// HandleRateLimitError handles rate limit errors
func HandleRateLimitError(c *gin.Context, retryAfter int) {
	LogWithContext(c).Warn("Rate limit exceeded")
	c.Header("Retry-After", string(rune(retryAfter)))
	c.JSON(http.StatusTooManyRequests, ErrorResponse{
		Error:   "Rate limit exceeded",
		Details: "Too many requests, please try again later",
	})
}
