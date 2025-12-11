package infrastructure

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

type RedisClient struct {
	Client *redis.Client
}

func NewRedisClient() (*RedisClient, error) {
	addr := os.Getenv("REDIS_ADDR")
	if addr == "" {
		host := getEnv("REDIS_HOST", "localhost")
		port := getEnv("REDIS_PORT", "6379")
		addr = fmt.Sprintf("%s:%s", host, port)
	}

	password := getEnv("REDIS_PASSWORD", "")

	client := redis.NewClient(&redis.Options{
		Addr:         addr,
		Password:     password,
		DB:           0,
		DialTimeout:  10 * time.Second,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
		PoolSize:     10,
		MinIdleConns: 5,
		MaxRetries:   3,
	})

	// Tenta conectar com retry
	ctx := context.Background()
	maxRetries := 15
	baseDelay := 1 * time.Second

	for i := 0; i < maxRetries; i++ {
		err := client.Ping(ctx).Err()
		if err == nil {
			log.Printf("✅ Successfully connected to Redis at %s", addr)
			return &RedisClient{Client: client}, nil
		}

		delay := baseDelay * time.Duration(1<<uint(min(i, 5))) // Max 32 segundos
		log.Printf("⚠️ Redis connection attempt %d/%d failed: %v. Retrying in %v...",
			i+1, maxRetries, err, delay)
		time.Sleep(delay)
	}

	return nil, fmt.Errorf("failed to connect to Redis at %s after %d attempts", addr, maxRetries)
}

func (r *RedisClient) Subscribe(ctx context.Context, channel string) *redis.PubSub {
	return r.Client.Subscribe(ctx, channel)
}

func (r *RedisClient) Close() error {
	return r.Client.Close()
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}