package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

// RateLimiter represents a rate limiter for a specific user
type RateLimiter struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

// RateLimitManager manages rate limiters for different users
type RateLimitManager struct {
	limiters map[string]*RateLimiter
	mutex    sync.RWMutex
	rate     rate.Limit
	burst    int
	cleanup  time.Duration
}

// NewRateLimitManager creates a new rate limit manager
func NewRateLimitManager(rateLimit rate.Limit, burst int, cleanupInterval time.Duration) *RateLimitManager {
	manager := &RateLimitManager{
		limiters: make(map[string]*RateLimiter),
		rate:     rateLimit,
		burst:    burst,
		cleanup:  cleanupInterval,
	}

	// Start cleanup goroutine
	go manager.cleanupExpiredLimiters()

	return manager
}

// GetLimiter gets or creates a rate limiter for a user
func (rlm *RateLimitManager) GetLimiter(userID string) *rate.Limiter {
	rlm.mutex.Lock()
	defer rlm.mutex.Unlock()

	limiter, exists := rlm.limiters[userID]
	if !exists {
		limiter = &RateLimiter{
			limiter:  rate.NewLimiter(rlm.rate, rlm.burst),
			lastSeen: time.Now(),
		}
		rlm.limiters[userID] = limiter
	} else {
		limiter.lastSeen = time.Now()
	}

	return limiter.limiter
}

// cleanupExpiredLimiters removes expired rate limiters
func (rlm *RateLimitManager) cleanupExpiredLimiters() {
	ticker := time.NewTicker(rlm.cleanup)
	defer ticker.Stop()

	for range ticker.C {
		rlm.mutex.Lock()
		now := time.Now()
		for userID, limiter := range rlm.limiters {
			if now.Sub(limiter.lastSeen) > rlm.cleanup*2 {
				delete(rlm.limiters, userID)
			}
		}
		rlm.mutex.Unlock()
	}
}

// PaymentRateLimitMiddleware creates a rate limiting middleware specifically for payment creation
func PaymentRateLimitMiddleware(rateLimit rate.Limit, burst int) gin.HandlerFunc {
	manager := NewRateLimitManager(rateLimit, burst, 5*time.Minute)

	return func(c *gin.Context) {
		// Get user ID from context
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"message": "User ID not found"})
			c.Abort()
			return
		}

		// Get rate limiter for user
		limiter := manager.GetLimiter(userID.(string))

		// Check if request is allowed
		if !limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"message": "Payment creation rate limit exceeded",
				"retry_after": time.Until(limiter.Reserve().DelayFrom(time.Now())).Seconds(),
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
