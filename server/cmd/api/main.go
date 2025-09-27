package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"zviewer-server/internal/config"
	"zviewer-server/internal/handlers"
	"zviewer-server/internal/middleware"
	"zviewer-server/internal/repositories"
	"zviewer-server/internal/services"
	"zviewer-server/pkg/database"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize logger
	logger := logrus.New()
	logger.SetLevel(logrus.InfoLevel)
	if cfg.Environment == "development" {
		logger.SetLevel(logrus.DebugLevel)
	}

	// Initialize database
	db, err := database.NewConnection(cfg.Database)
	if err != nil {
		logger.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Run migrations
	if err := database.RunMigrations(cfg.Database); err != nil {
		logger.Fatalf("Failed to run migrations: %v", err)
	}

	// Initialize Gin router
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Add middleware
	router.Use(middleware.Logger(logger))
	router.Use(middleware.Recovery(logger))
	router.Use(middleware.CORS())

	// Initialize repositories
	albumRepo := repositories.NewAlbumRepository(db, logger)
	mediaRepo := repositories.NewMediaRepository(db, logger)

	// Initialize services
	albumService := services.NewAlbumService(albumRepo, logger)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(db, logger, cfg.JWT)
	albumHandler := handlers.NewAlbumHandler(albumService, logger)
	mediaHandler := handlers.NewMediaHandler(mediaRepo, logger, "./services/media/uploads/media")
	proxyHandler := handlers.NewProxyHandler(cfg.Services.MediaServiceURL, logger)

	// Setup routes
	api := router.Group("/api")
	{
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/logout", middleware.AuthRequired(cfg.JWT), authHandler.Logout)
			auth.GET("/me", middleware.AuthRequired(cfg.JWT), authHandler.GetMe)
		}

		// Admin routes
		admin := api.Group("/admin")
		admin.Use(middleware.AuthRequired(cfg.JWT))
		{
			albums := admin.Group("/albums")
			{
				albums.POST("", albumHandler.CreateAlbum)
				albums.GET("", albumHandler.GetAlbums)
				albums.GET("/search", albumHandler.SearchAlbums)
				albums.GET("/:id", albumHandler.GetAlbum)
				albums.PUT("/:id", albumHandler.UpdateAlbum)
				albums.DELETE("/:id", albumHandler.DeleteAlbum)
				albums.POST("/:id/images", albumHandler.AddImagesToAlbum)
				albums.DELETE("/:id/images", albumHandler.RemoveImagesFromAlbum)
				albums.PUT("/:id/cover", albumHandler.SetAlbumCover)
			}
		}

		// Public routes
		public := api.Group("/public")
		{
			albums := public.Group("/albums")
			{
				albums.GET("", albumHandler.GetAlbums) // Public albums only
				albums.GET("/:id", albumHandler.GetAlbum)
			}
		}

	}

	// Public media routes (no auth required for streaming)
	media := router.Group("/api/media")
	{
		// Direct media streaming (no auth required for public access)
		media.GET("/stream/:id", mediaHandler.StreamMedia)
		media.GET("/thumbnail/:id", mediaHandler.GetThumbnail)
	}

	// Media service proxy routes (with auth) - use different path to avoid conflict
	mediaProxy := router.Group("/api/media-proxy")
	mediaProxy.Use(middleware.AuthRequired(cfg.JWT))
	{
		// Other media requests can be proxied to media service if needed
		mediaProxy.Any("/*path", proxyHandler.ProxyToMediaService)
	}

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// Start server
	srv := &http.Server{
		Addr:    ":" + cfg.Server.Port,
		Handler: router,
	}

	// Graceful shutdown
	go func() {
		logger.Infof("Server starting on port %s", cfg.Server.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("Shutting down server...")

	// Give outstanding requests 30 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatalf("Server forced to shutdown: %v", err)
	}

	logger.Info("Server exited")
}
