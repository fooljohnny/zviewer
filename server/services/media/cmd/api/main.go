package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"zviewer-media-service/internal/config"
	"zviewer-media-service/internal/handlers"
	"zviewer-media-service/internal/middleware"
	"zviewer-media-service/internal/repositories"
	"zviewer-media-service/internal/services"
	"zviewer-media-service/internal/storage"
	"zviewer-media-service/pkg/database"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Set up logging
	logrus.SetLevel(logrus.InfoLevel)
	logrus.SetFormatter(&logrus.JSONFormatter{})

	// Initialize database connection
	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Run database migrations
	if err := database.RunMigrations(db, "migrations"); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// Initialize repositories
	mediaRepo := repositories.NewMediaRepository(db)

	// Initialize services
	mediaService := services.NewMediaService(mediaRepo, cfg)

	// Create storage factory and get storage instance
	storageFactory := storage.NewStorageFactory()
	storageInstance, err := storageFactory.CreateStorage(cfg)
	if err != nil {
		log.Fatalf("Failed to create storage: %v", err)
	}

	// Initialize upload service
	pathGen := storage.NewPathGenerator()
	uploadService := services.NewUploadService(storageInstance, pathGen, cfg)

	// Initialize WebSocket handler
	wsHandler := handlers.NewWebSocketHandler()

	// Initialize handlers
	mediaHandler := handlers.NewMediaHandler(mediaService, uploadService, wsHandler)

	// Set up Gin router
	router := gin.New()
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(middleware.CORS())

	// Set up routes
	api := router.Group("/api")
	{
		media := api.Group("/media")
		media.Use(middleware.AuthRequired(cfg.JWTSecret))
		{
			media.POST("/upload", mediaHandler.UploadMedia)
			media.POST("/chunked/start", mediaHandler.StartChunkedUpload)
			media.POST("/chunked/upload", mediaHandler.UploadChunk)
			media.GET("/progress/:uploadId", mediaHandler.GetUploadProgress)
			media.GET("/:id", mediaHandler.GetMedia)
			media.GET("/:id/stream", mediaHandler.StreamMedia)
			media.GET("/:id/thumbnail", mediaHandler.GetThumbnail)
			media.PUT("/:id", mediaHandler.UpdateMedia)
			media.DELETE("/:id", mediaHandler.DeleteMedia)
			media.GET("", mediaHandler.ListMedia)
		}

		// WebSocket endpoint (no auth required for WebSocket upgrade)
		api.GET("/ws/upload-progress", mediaHandler.HandleWebSocket)
	}

	// Public media streaming routes (no auth required for public access)
	// These routes match the Flutter app's expected URL patterns
	mediaPublic := router.Group("/api/media")
	{
		mediaPublic.GET("/stream/:id", mediaHandler.StreamMedia)
		mediaPublic.GET("/thumbnail/:id", mediaHandler.GetThumbnail)
	}

	// Health check endpoint
	api.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy"})
	})

	// Start server
	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: router,
	}

	// Graceful shutdown
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	logrus.Infof("Media service started on port %s", cfg.Port)

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logrus.Info("Shutting down media service...")

	// Give outstanding requests 30 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	logrus.Info("Media service stopped")
}
