package services

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/joho/go-dotenv"
)

func init() {
	// Carrega variáveis de ambiente para testes
	if err := godotenv.Load("../../.env.test"); err != nil {
		log.Println("No .env.test file found, using environment variables")
	}
}

// setupRedisForTest cria um Redis manager com configurações robustas para testes
func setupRedisForTest() (*RedisManager, error) {
	host := getEnvOrDefault("REDIS_HOST", "localhost")
	port := getEnvOrDefault("REDIS_PORT", "6379")
	password := getEnvOrDefault("REDIS_PASSWORD", "")
	
	redisManager := NewRedisManager(host, port, password, 0, 10, 5, 5) // Mais retries para testes
	
	// Aguarda um pouco para garantir estabilidade
	time.Sleep(500 * time.Millisecond)
	
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	
	if err := redisManager.Connect(ctx); err != nil {
		return nil, err
	}
	
	return redisManager, nil
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}