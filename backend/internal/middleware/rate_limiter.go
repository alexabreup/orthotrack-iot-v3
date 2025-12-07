package middleware

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

// Simple in-memory rate limiter for production use Redis-based limiter
type RateLimiter struct {
	limiter *rate.Limiter
	limit   rate.Limit
	burst   int
}

func NewRateLimiter(requestsPerSecond int, burstSize int) *RateLimiter {
	limit := rate.Limit(requestsPerSecond)
	return &RateLimiter{
		limiter: rate.NewLimiter(limit, burstSize),
		limit:   limit,
		burst:   burstSize,
	}
}

func (rl *RateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !rl.limiter.Allow() {
			c.Header("X-RateLimit-Limit", fmt.Sprintf("%v", rl.limit))
			c.Header("X-RateLimit-Remaining", "0")
			c.Header("Retry-After", "1")
			
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Rate limit exceeded",
				"message": "Too many requests, please try again later",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

// Per-IP rate limiter (simple version - use Redis in production)
type IPRateLimiter struct {
	limiters map[string]*rate.Limiter
	limit    rate.Limit
	burst    int
}

func NewIPRateLimiter(requestsPerSecond int, burstSize int) *IPRateLimiter {
	return &IPRateLimiter{
		limiters: make(map[string]*rate.Limiter),
		limit:    rate.Limit(requestsPerSecond),
		burst:    burstSize,
	}
}

func (ipl *IPRateLimiter) getLimiter(ip string) *rate.Limiter {
	if limiter, exists := ipl.limiters[ip]; exists {
		return limiter
	}
	
	limiter := rate.NewLimiter(ipl.limit, ipl.burst)
	ipl.limiters[ip] = limiter
	
	// Clean up old limiters (simple approach - in production use TTL with Redis)
	go func() {
		time.Sleep(time.Hour)
		delete(ipl.limiters, ip)
	}()
	
	return limiter
}

func (ipl *IPRateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		limiter := ipl.getLimiter(ip)
		
		if !limiter.Allow() {
			c.Header("X-RateLimit-Limit", fmt.Sprintf("%v", ipl.limit))
			c.Header("X-RateLimit-Remaining", "0")
			c.Header("Retry-After", "1")
			
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Rate limit exceeded",
				"message": "Too many requests from this IP, please try again later",
				"ip": ip,
			})
			c.Abort()
			return
		}
		
		c.Next()
	}
}