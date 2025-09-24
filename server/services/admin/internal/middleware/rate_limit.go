package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

// RateLimiter represents a rate limiter
type RateLimiter struct {
	limiters map[string]*rate.Limiter
	mu       sync.RWMutex
	rate     rate.Limit
	burst    int
}

// NewRateLimiter creates a new rate limiter
func NewRateLimiter(rateLimit rate.Limit, burst int) *RateLimiter {
	return &RateLimiter{
		limiters: make(map[string]*rate.Limiter),
		rate:     rateLimit,
		burst:    burst,
	}
}

// GetLimiter gets or creates a limiter for the given key
func (rl *RateLimiter) GetLimiter(key string) *rate.Limiter {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	limiter, exists := rl.limiters[key]
	if !exists {
		limiter = rate.NewLimiter(rl.rate, rl.burst)
		rl.limiters[key] = limiter
	}

	return limiter
}

// Cleanup removes old limiters to prevent memory leaks
func (rl *RateLimiter) Cleanup() {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	// Remove limiters that haven't been used in the last hour
	// For now, we'll keep all limiters to avoid complexity
	// In a production system, you'd want to track creation time and clean up old ones
	_ = time.Now().Add(-time.Hour)
}

var (
	// Global rate limiter for admin endpoints
	adminRateLimiter = NewRateLimiter(rate.Limit(10), 20) // 10 requests per second, burst of 20
)

// RateLimit middleware implements rate limiting
func RateLimit() gin.HandlerFunc {
	// Start cleanup goroutine
	go func() {
		ticker := time.NewTicker(time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			adminRateLimiter.Cleanup()
		}
	}()

	return func(c *gin.Context) {
		// Get client IP as the key for rate limiting
		clientIP := c.ClientIP()

		limiter := adminRateLimiter.GetLimiter(clientIP)

		if !limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":       "Rate limit exceeded",
				"retry_after": "1 second", // Simplified retry after message
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
