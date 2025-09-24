package middleware

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Validation middleware provides input validation
func Validation() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Validate UUID parameters
		if err := validateUUIDParams(c); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			c.Abort()
			return
		}

		// Validate query parameters
		if err := validateQueryParams(c); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			c.Abort()
			return
		}

		c.Next()
	}
}

// validateUUIDParams validates UUID path parameters
func validateUUIDParams(c *gin.Context) error {
	// Check common UUID parameters
	uuidParams := []string{"id", "user_id", "content_id", "comment_id", "payment_id"}

	for _, param := range uuidParams {
		if value := c.Param(param); value != "" {
			if _, err := uuid.Parse(value); err != nil {
				return fmt.Errorf("invalid %s: %s", param, value)
			}
		}
	}

	return nil
}

// validateQueryParams validates query parameters
func validateQueryParams(c *gin.Context) error {
	// Validate pagination parameters
	if page := c.Query("page"); page != "" {
		if page == "0" || page == "-1" {
			return fmt.Errorf("page must be a positive integer")
		}
	}

	if limit := c.Query("limit"); limit != "" {
		if limit == "0" || limit == "-1" {
			return fmt.Errorf("limit must be a positive integer")
		}
	}

	// Validate status parameters
	if status := c.Query("status"); status != "" {
		validStatuses := []string{"active", "inactive", "suspended", "banned", "pending", "approved", "rejected", "flagged"}
		if !contains(validStatuses, status) {
			return fmt.Errorf("invalid status: %s", status)
		}
	}

	// Validate role parameters
	if role := c.Query("role"); role != "" {
		validRoles := []string{"admin", "user", "moderator"}
		if !contains(validRoles, role) {
			return fmt.Errorf("invalid role: %s", role)
		}
	}

	return nil
}

// contains checks if a slice contains a string
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
