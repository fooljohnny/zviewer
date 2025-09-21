package handlers

import (
	"database/sql"
	"net/http"

	"zviewer-server/internal/config"
	"zviewer-server/internal/middleware"
	"zviewer-server/internal/models"
	"zviewer-server/internal/repositories"
	"zviewer-server/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// AuthHandler handles authentication HTTP requests
type AuthHandler struct {
	authService *services.AuthService
	logger      *logrus.Logger
}

// NewAuthHandler creates a new auth handler
func NewAuthHandler(db *sql.DB, logger *logrus.Logger, jwtCfg config.JWTConfig) *AuthHandler {
	userRepo := repositories.NewUserRepository(db)
	authService := services.NewAuthService(userRepo, jwtCfg)
	
	return &AuthHandler{
		authService: authService,
		logger:      logger,
	}
}

// Register handles user registration
func (h *AuthHandler) Register(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.WithError(err).Debug("Invalid registration request")
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Invalid request data",
		})
		return
	}

	// Register user
	authResponse, err := h.authService.Register(&req)
	if err != nil {
		h.logger.WithError(err).Debug("Registration failed")
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: err.Error(),
		})
		return
	}

	h.logger.WithField("user_id", authResponse.User.ID).Info("User registered successfully")
	c.JSON(http.StatusCreated, authResponse)
}

// Login handles user login
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.WithError(err).Debug("Invalid login request")
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Message: "Invalid request data",
		})
		return
	}

	// Authenticate user
	authResponse, err := h.authService.Login(&req)
	if err != nil {
		h.logger.WithError(err).Debug("Login failed")
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Message: "Invalid credentials",
		})
		return
	}

	h.logger.WithField("user_id", authResponse.User.ID).Info("User logged in successfully")
	c.JSON(http.StatusOK, authResponse)
}

// Logout handles user logout
func (h *AuthHandler) Logout(c *gin.Context) {
	// Get user ID from context (set by AuthRequired middleware)
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Message: "User not authenticated",
		})
		return
	}

	h.logger.WithField("user_id", userID).Info("User logged out successfully")
	c.JSON(http.StatusOK, gin.H{})
}

// GetMe handles getting current user info
func (h *AuthHandler) GetMe(c *gin.Context) {
	// Get user ID from context (set by AuthRequired middleware)
	userID, exists := middleware.GetUserIDFromContext(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Message: "User not authenticated",
		})
		return
	}

	// Get user info
	user, err := h.authService.GetUserByID(userID)
	if err != nil {
		h.logger.WithError(err).WithField("user_id", userID).Debug("Failed to get user")
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Message: "User not found",
		})
		return
	}

	c.JSON(http.StatusOK, user)
}
