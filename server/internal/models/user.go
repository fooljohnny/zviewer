package models

import (
	"time"

	"github.com/google/uuid"
)

// UserRole represents the role of a user
type UserRole string

const (
	UserRoleUser      UserRole = "user"
	UserRoleAdmin     UserRole = "admin"
	UserRoleModerator UserRole = "moderator"
)

// User represents a user in the system
type User struct {
	ID          string    `json:"id" db:"id"`
	Email       string    `json:"email" db:"email"`
	DisplayName *string   `json:"displayName" db:"display_name"`
	Role        UserRole  `json:"role" db:"role"`
	CreatedAt   time.Time `json:"createdAt" db:"created_at"`
	LastLoginAt *time.Time `json:"lastLoginAt" db:"last_login_at"`
	PasswordHash string   `json:"-" db:"password_hash"`
}

// AuthResponse represents the response for authentication endpoints
type AuthResponse struct {
	Token     string    `json:"token"`
	User      User      `json:"user"`
	ExpiresAt time.Time `json:"expiresAt"`
}

// RegisterRequest represents the request for user registration
type RegisterRequest struct {
	Email           string `json:"email" binding:"required,email"`
	Password        string `json:"password" binding:"required,min=8"`
	ConfirmPassword string `json:"confirmPassword" binding:"required"`
}

// LoginRequest represents the request for user login
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Message string `json:"message"`
}

// NewUser creates a new user with generated ID
func NewUser(email, passwordHash string, role UserRole) *User {
	now := time.Now()
	return &User{
		ID:           uuid.New().String(),
		Email:        email,
		Role:         role,
		CreatedAt:    now,
		PasswordHash: passwordHash,
	}
}

// IsAdmin returns true if the user is an admin
func (u *User) IsAdmin() bool {
	return u.Role == UserRoleAdmin
}

// IsModerator returns true if the user is a moderator or admin
func (u *User) IsModerator() bool {
	return u.Role == UserRoleModerator || u.Role == UserRoleAdmin
}

// IsUser returns true if the user is a regular user
func (u *User) IsUser() bool {
	return u.Role == UserRoleUser
}

// UpdateLastLogin updates the last login time
func (u *User) UpdateLastLogin() {
	now := time.Now()
	u.LastLoginAt = &now
}

// ToPublicUser returns a user without sensitive information
func (u *User) ToPublicUser() *User {
	return &User{
		ID:          u.ID,
		Email:       u.Email,
		DisplayName: u.DisplayName,
		Role:        u.Role,
		CreatedAt:   u.CreatedAt,
		LastLoginAt: u.LastLoginAt,
		// PasswordHash is intentionally omitted
	}
}
