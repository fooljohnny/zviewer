package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"zviewer-payments-service/internal/config"
	"zviewer-payments-service/internal/handlers"
	"zviewer-payments-service/internal/middleware"
	"zviewer-payments-service/internal/repositories"
	"zviewer-payments-service/internal/services"
	"zviewer-payments-service/pkg/database"

	"golang.org/x/time/rate"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"github.com/stripe/stripe-go/v76"
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

	// Initialize Stripe
	stripe.Key = cfg.StripeSecretKey

	// Initialize database connection
	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.Close(db)

	// Initialize repositories
	paymentRepo := repositories.NewPaymentRepository(db)
	subscriptionRepo := repositories.NewSubscriptionRepository(db)
	paymentMethodRepo := repositories.NewPaymentMethodRepository(db)

	// Initialize services
	stripeService := services.NewStripeService(cfg)
	paymentService := services.NewPaymentService(paymentRepo, stripeService, cfg)
	subscriptionService := services.NewSubscriptionService(subscriptionRepo, stripeService, cfg)
	paymentMethodService := services.NewPaymentMethodService(paymentMethodRepo, stripeService, cfg)

	// Initialize handlers
	paymentHandler := handlers.NewPaymentHandler(paymentService)
	subscriptionHandler := handlers.NewSubscriptionHandler(subscriptionService)
	paymentMethodHandler := handlers.NewPaymentMethodHandler(paymentMethodService)
	webhookHandler := handlers.NewWebhookHandler(stripeService, paymentService, subscriptionService, cfg)

	// Set up Gin router
	router := gin.New()
	router.Use(gin.Logger())
	router.Use(middleware.ErrorHandler())
	router.Use(middleware.CORS())
	router.Use(middleware.TracingMiddleware())

	// Set up routes
	api := router.Group("/api/v1")
	{
		payments := api.Group("/payments")
		{
			// Public routes (no auth required)
			payments.POST("/webhooks/stripe", webhookHandler.HandleStripeWebhook)

			// Protected routes (auth required)
			payments.Use(middleware.AuthRequired(cfg.JWTSecret))
			{
				// Apply rate limiting to payment creation
				payments.POST("", middleware.PaymentRateLimitMiddleware(rate.Limit(cfg.PaymentRateLimit)/rate.Limit(cfg.RateLimitWindow.Minutes()), 5), paymentHandler.CreatePayment)
				payments.GET("", paymentHandler.ListPayments)
				payments.GET("/:id", paymentHandler.GetPayment)
				payments.POST("/:id/refund", paymentHandler.ProcessRefund)

				// Subscription routes
				subscriptions := payments.Group("/subscriptions")
				{
					subscriptions.GET("", subscriptionHandler.ListSubscriptions)
					subscriptions.POST("", subscriptionHandler.CreateSubscription)
					subscriptions.GET("/:id", subscriptionHandler.GetSubscription)
					subscriptions.PUT("/:id", subscriptionHandler.UpdateSubscription)
					subscriptions.DELETE("/:id", subscriptionHandler.CancelSubscription)
				}

				// Payment method routes
				paymentMethods := payments.Group("/payment-methods")
				{
					paymentMethods.GET("", paymentMethodHandler.ListPaymentMethods)
					paymentMethods.POST("", paymentMethodHandler.CreatePaymentMethod)
					paymentMethods.GET("/:id", paymentMethodHandler.GetPaymentMethod)
					paymentMethods.PUT("/:id", paymentMethodHandler.UpdatePaymentMethod)
					paymentMethods.DELETE("/:id", paymentMethodHandler.DeletePaymentMethod)
				}
			}

			// Admin routes
			admin := payments.Group("")
			admin.Use(middleware.AdminRequired())
			{
				admin.GET("/stats", paymentHandler.GetStats)
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

	logrus.Infof("Payments service started on port %s", cfg.Port)

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logrus.Info("Shutting down payments service...")

	// Give outstanding requests 30 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	logrus.Info("Payments service stopped")
}
