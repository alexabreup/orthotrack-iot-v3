package middleware

import (
	"net/http"
	"orthotrack-iot-v3/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// DeviceAuthMiddleware autentica dispositivos via API key ou device token
func DeviceAuthMiddleware() gin.HandlerFunc {
	return DeviceAuthWithDB(nil)
}

// DeviceAuthWithDB permite injetar uma conexão de banco de dados para validação
func DeviceAuthWithDB(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Verificar API Key no header
		apiKey := c.GetHeader("X-Device-API-Key")
		if apiKey == "" {
			// Tentar no query parameter
			apiKey = c.Query("api_key")
		}

		// Tentar device ID como alternativa
		deviceID := c.GetHeader("X-Device-ID")
		if deviceID == "" && apiKey == "" {
			deviceID = c.Query("device_id")
		}

		if apiKey == "" && deviceID == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Device API key or Device ID required"})
			c.Abort()
			return
		}

		// Validar API key/device ID contra banco de dados
		if db != nil {
			var brace models.Brace
			var query *gorm.DB
			
			if apiKey != "" {
				// Primeiro tenta validar por API key (se implementado no modelo)
				query = db.Where("api_key = ? OR device_id = ?", apiKey, apiKey)
			} else {
				// Validar por device ID
				query = db.Where("device_id = ?", deviceID)
			}

			if err := query.First(&brace).Error; err != nil {
				if err == gorm.ErrRecordNotFound {
					c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid device credentials"})
				} else {
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Authentication error"})
				}
				c.Abort()
				return
			}

			// Verificar se dispositivo está ativo
			if brace.Status != "active" {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Device not active"})
				c.Abort()
				return
			}

			// Adicionar informações do dispositivo no contexto
			c.Set("device_id", brace.DeviceID)
			c.Set("brace_id", brace.ID)
		} else {
			// Modo desenvolvimento - aceita qualquer chave não vazia
			c.Set("device_api_key", apiKey)
			if deviceID != "" {
				c.Set("device_id", deviceID)
			}
		}

		c.Next()
	}
}

















