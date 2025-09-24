package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"zviewer-admin-service/internal/config"
	"zviewer-admin-service/internal/handlers"
	"zviewer-admin-service/internal/middleware"
	"zviewer-admin-service/internal/repositories"
	"zviewer-admin-service/internal/services"
	"zviewer-admin-service/pkg/database"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Setup logging
	setupLogging(cfg.Logging)

	logrus.Info("Starting ZViewer Admin Service...")

	// Initialize database
	db, err := database.Connect(cfg.Database)
	if err != nil {
		logrus.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Initialize repositories
	adminActionRepo := repositories.NewAdminActionRepository(db)
	contentModerationRepo := repositories.NewContentModerationRepository(db)
	systemStatsRepo := repositories.NewSystemStatsRepository(db)

	// Initialize services
	integrationService := services.NewIntegrationService(cfg.Services)
	userManagementService := services.NewUserManagementService(adminActionRepo, integrationService)
	contentManagementService := services.NewContentManagementService(contentModerationRepo, integrationService)
	moderationService := services.NewModerationService(contentModerationRepo, adminActionRepo)
	systemService := services.NewSystemService(systemStatsRepo, adminActionRepo)

	// Initialize handlers
	userHandler := handlers.NewUserManagementHandler(userManagementService)
	contentHandler := handlers.NewContentManagementHandler(contentManagementService)
	moderationHandler := handlers.NewModerationHandler(moderationService)
	systemHandler := handlers.NewSystemHandler(systemService)

	// Setup router
	router := setupRouter(cfg, userHandler, contentHandler, moderationHandler, systemHandler)

	// Start server
	server := &http.Server{
		Addr:         fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port),
		Handler:      router,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
	}

	// Start server in a goroutine
	go func() {
		logrus.Infof("Admin service starting on %s:%s", cfg.Server.Host, cfg.Server.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logrus.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logrus.Info("Shutting down admin service...")

	// Give outstanding requests 30 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logrus.Fatalf("Server forced to shutdown: %v", err)
	}

	logrus.Info("Admin service exited")
}

func setupLogging(cfg config.LoggingConfig) {
	// Set log level
	level, err := logrus.ParseLevel(cfg.Level)
	if err != nil {
		level = logrus.InfoLevel
	}
	logrus.SetLevel(level)

	// Set log format
	if cfg.Format == "json" {
		logrus.SetFormatter(&logrus.JSONFormatter{})
	} else {
		logrus.SetFormatter(&logrus.TextFormatter{})
	}
}

func setupRouter(cfg *config.Config, userHandler *handlers.UserManagementHandler, contentHandler *handlers.ContentManagementHandler, moderationHandler *handlers.ModerationHandler, systemHandler *handlers.SystemHandler) *gin.Engine {
	// Set Gin mode
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Global middleware
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(middleware.CORS())
	router.Use(middleware.Tracing())
	router.Use(middleware.RateLimit())
	router.Use(middleware.Validation())

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "admin"})
	})

	// API v1 routes
	v1 := router.Group("/api/v1/admin")
	{
		// Authentication middleware for all admin routes
		v1.Use(middleware.Auth(cfg.JWT))
		v1.Use(middleware.AdminAuth())

		// User management routes
		users := v1.Group("/users")
		{
			users.GET("", userHandler.ListUsers)
			users.GET("/:id", userHandler.GetUser)
			users.POST("", userHandler.CreateUser)
			users.PUT("/:id", userHandler.UpdateUser)
			users.DELETE("/:id", userHandler.DeleteUser)
			users.PUT("/:id/role", userHandler.UpdateUserRole)
			users.PUT("/:id/status", userHandler.UpdateUserStatus)
			users.GET("/:id/activity", userHandler.GetUserActivity)
		}

		// Content management routes
		content := v1.Group("/content")
		{
			content.GET("", contentHandler.ListContent)
			content.GET("/:id", contentHandler.GetContent)
			content.PUT("/:id/status", contentHandler.UpdateContentStatus)
			content.POST("/:id/flag", contentHandler.FlagContent)
			content.GET("/flagged", contentHandler.GetFlaggedContent)
			content.POST("/bulk-action", contentHandler.BulkAction)
			content.GET("/stats", contentHandler.GetContentStats)
		}

		// Moderation routes
		moderation := v1.Group("/moderation")
		{
			moderation.GET("/queue", moderationHandler.GetModerationQueue)
			moderation.POST("/review", moderationHandler.SubmitModerationDecision)
			moderation.GET("/history", moderationHandler.GetModerationHistory)
			moderation.POST("/bulk-review", moderationHandler.BulkModeration)
		}

		// System management routes
		stats := v1.Group("/stats")
		{
			stats.GET("/overview", systemHandler.GetOverviewStats)
			stats.GET("/users", systemHandler.GetUserStats)
			stats.GET("/content", systemHandler.GetContentStats)
			stats.GET("/payments", systemHandler.GetPaymentStats)
		}

		// Audit logs
		v1.GET("/logs/audit", systemHandler.GetAuditLogs)
	}

	return router
}
