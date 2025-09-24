package middleware

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

const (
	UserIDKey    = "user_id"
	UserEmailKey = "user_email"
	UserRoleKey  = "user_role"
	UsernameKey  = "user_username"
)

// GetUserID extracts user ID from context
func GetUserID(c *gin.Context) (uuid.UUID, error) {
	userIDStr, exists := c.Get(UserIDKey)
	if !exists {
		return uuid.Nil, fmt.Errorf("user ID not found in context")
	}

	userID, ok := userIDStr.(string)
	if !ok {
		return uuid.Nil, fmt.Errorf("invalid user ID type in context")
	}

	return uuid.Parse(userID)
}

// GetUserEmail extracts user email from context
func GetUserEmail(c *gin.Context) (string, error) {
	email, exists := c.Get(UserEmailKey)
	if !exists {
		return "", fmt.Errorf("user email not found in context")
	}

	emailStr, ok := email.(string)
	if !ok {
		return "", fmt.Errorf("invalid user email type in context")
	}

	return emailStr, nil
}

// GetUserRole extracts user role from context
func GetUserRole(c *gin.Context) (string, error) {
	role, exists := c.Get(UserRoleKey)
	if !exists {
		return "", fmt.Errorf("user role not found in context")
	}

	roleStr, ok := role.(string)
	if !ok {
		return "", fmt.Errorf("invalid user role type in context")
	}

	return roleStr, nil
}

// GetUsername extracts username from context
func GetUsername(c *gin.Context) (string, error) {
	username, exists := c.Get(UsernameKey)
	if !exists {
		return "", fmt.Errorf("username not found in context")
	}

	usernameStr, ok := username.(string)
	if !ok {
		return "", fmt.Errorf("invalid username type in context")
	}

	return usernameStr, nil
}
