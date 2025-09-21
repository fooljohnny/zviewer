package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"zviewer-comments-service/internal/config"
	"zviewer-comments-service/internal/handlers"
	"zviewer-comments-service/internal/middleware"
	"zviewer-comments-service/internal/repositories"
	"zviewer-comments-service/internal/services"
	"zviewer-comments-service/pkg/database"

	"golang.org/x/time/rate"

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
	defer database.Close(db)

	// Initialize repositories
	commentRepo := repositories.NewCommentRepository(db)

	// Initialize services
	commentService := services.NewCommentService(commentRepo, cfg)

	// Initialize handlers
	commentHandler := handlers.NewCommentHandler(commentService)

	// Set up Gin router
	router := gin.New()
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(middleware.CORS())
	router.Use(middleware.TracingMiddleware())

	// Set up routes
	api := router.Group("/api/v1")
	{
		comments := api.Group("/comments")
		{
			// Public routes (no auth required)
			comments.GET("", commentHandler.ListComments)
			comments.GET("/:id", commentHandler.GetComment)
			comments.GET("/media/:mediaId", commentHandler.GetCommentsByMedia)
			comments.GET("/:id/replies", commentHandler.GetReplies)
			comments.GET("/stats/user/:userId", commentHandler.GetUserStats)
			comments.GET("/stats/media/:mediaId", commentHandler.GetMediaStats)

			// Protected routes (auth required)
			comments.Use(middleware.AuthRequired(cfg.JWTSecret))
			{
				// Apply rate limiting to comment creation
				comments.POST("", middleware.CommentRateLimitMiddleware(rate.Limit(cfg.CommentRateLimit)/rate.Limit(cfg.RateLimitWindow.Minutes()), 5), commentHandler.CreateComment)
				comments.PUT("/:id", commentHandler.UpdateComment)
				comments.DELETE("/:id", commentHandler.DeleteComment)
				comments.POST("/:id/reply", middleware.CommentRateLimitMiddleware(rate.Limit(cfg.CommentRateLimit)/rate.Limit(cfg.RateLimitWindow.Minutes()), 5), commentHandler.ReplyToComment)
			}

			// Admin routes
			admin := comments.Group("")
			admin.Use(middleware.AdminRequired())
			{
				admin.GET("/stats", commentHandler.GetStats)
				admin.POST("/:id/moderate", commentHandler.ModerateComment)
			}
		}
	}

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
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

	logrus.Infof("Comments service started on port %s", cfg.Port)

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logrus.Info("Shutting down comments service...")

	// Give outstanding requests 30 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	logrus.Info("Comments service stopped")
}
