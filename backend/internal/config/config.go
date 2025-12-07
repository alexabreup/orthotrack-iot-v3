package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	Port     string
	Database DatabaseConfig
	Redis    RedisConfig
	JWT      JWTConfig
	AI       AIConfig
	MQTT     MQTTConfig
	IoT      IoTConfig
}

type DatabaseConfig struct {
	Host     string
	Port     string
	Name     string
	User     string
	Password string
	SSLMode  string
}

type RedisConfig struct {
	Host     string
	Port     string
	Password string
	DB       int
}

type JWTConfig struct {
	Secret     string
	ExpireHours int
}

type AIConfig struct {
	OpenAIKey    string
	DeepSeekKey  string
	DefaultModel string
}

type MQTTConfig struct {
	BrokerURL string
	ClientID  string
	Username  string
	Password  string
}

type IoTConfig struct {
	GatewayEnabled    bool
	WebSocketPort     string
	TelemetryRetention int // days
	AlertThresholds   AlertThresholds
}

type AlertThresholds struct {
	BatteryLow        int     // percentage
	ComplianceLow     float64 // percentage
	TempHigh          float64 // celsius
	TempLow           float64 // celsius
	OfflineTimeout    int     // minutes
}

func Load() *Config {
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	redisDB, _ := strconv.Atoi(getEnv("REDIS_DB", "0"))
	jwtExpire, _ := strconv.Atoi(getEnv("JWT_EXPIRE_HOURS", "24"))
	batteryLow, _ := strconv.Atoi(getEnv("ALERT_BATTERY_LOW", "20"))
	complianceLow, _ := strconv.ParseFloat(getEnv("ALERT_COMPLIANCE_LOW", "80"), 64)
	tempHigh, _ := strconv.ParseFloat(getEnv("ALERT_TEMP_HIGH", "40"), 64)
	tempLow, _ := strconv.ParseFloat(getEnv("ALERT_TEMP_LOW", "5"), 64)
	offlineTimeout, _ := strconv.Atoi(getEnv("ALERT_OFFLINE_TIMEOUT", "120"))
	telemetryRetention, _ := strconv.Atoi(getEnv("TELEMETRY_RETENTION_DAYS", "30"))

	return &Config{
		Port: getEnv("PORT", "8080"),
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
			Name:     getEnvRequired("DB_NAME"),
			User:     getEnvRequired("DB_USER"),
			Password: getEnvRequired("DB_PASSWORD"),
			SSLMode:  getEnv("DB_SSL_MODE", "require"), // Default mais seguro
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnv("REDIS_PORT", "6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       redisDB,
		},
		JWT: JWTConfig{
			Secret:      getEnvRequired("JWT_SECRET"),
			ExpireHours: jwtExpire,
		},
		AI: AIConfig{
			OpenAIKey:    getEnv("OPENAI_API_KEY", ""),
			DeepSeekKey:  getEnv("DEEPSEEK_API_KEY", ""),
			DefaultModel: getEnv("AI_DEFAULT_MODEL", "openai"),
		},
		MQTT: MQTTConfig{
			BrokerURL: getEnvRequired("MQTT_BROKER_URL"),
			ClientID:  getEnv("MQTT_CLIENT_ID", "orthotrack-backend"),
			Username:  getEnvRequired("MQTT_USERNAME"),
			Password:  getEnvRequired("MQTT_PASSWORD"),
		},
		IoT: IoTConfig{
			GatewayEnabled:     getEnv("IOT_GATEWAY_ENABLED", "true") == "true",
			WebSocketPort:      getEnv("WEBSOCKET_PORT", "8081"),
			TelemetryRetention: telemetryRetention,
			AlertThresholds: AlertThresholds{
				BatteryLow:     batteryLow,
				ComplianceLow:  complianceLow,
				TempHigh:       tempHigh,
				TempLow:        tempLow,
				OfflineTimeout: offlineTimeout,
			},
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvRequired(key string) string {
	value := os.Getenv(key)
	if value == "" {
		log.Fatalf("Required environment variable %s is not set", key)
	}
	return value
}