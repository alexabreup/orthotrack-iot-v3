package middleware

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/gorilla/websocket"
)

// WebSocketAuthMiddleware handles JWT authentication for WebSocket connections
type WebSocketAuthMiddleware struct {
	jwtSecret string
	upgrader  websocket.Upgrader
}

// NewWebSocketAuthMiddleware creates a new WebSocket authentication middleware
func NewWebSocketAuthMiddleware(jwtSecret string) *WebSocketAuthMiddleware {
	return &WebSocketAuthMiddleware{
		jwtSecret: jwtSecret,
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			CheckOrigin: func(r *http.Request) bool {
				// TODO: Implement proper CORS checking in production
				return true
			},
		},
	}
}

// ValidateWebSocketToken validates JWT token from query parameter or header
// Returns user_id, institution_id, role, token_expiry, and error
func (m *WebSocketAuthMiddleware) ValidateWebSocketToken(c *gin.Context) (string, string, string, time.Time, error) {
	// Try to get token from query parameter first (common for WebSocket)
	tokenString := c.Query("token")
	
	// If not in query, try Authorization header
	if tokenString == "" {
		authHeader := c.GetHeader("Authorization")
		if authHeader != "" {
			parts := strings.Split(authHeader, " ")
			if len(parts) == 2 && parts[0] == "Bearer" {
				tokenString = parts[1]
			}
		}
	}

	// If still no token, try Sec-WebSocket-Protocol header (alternative method)
	if tokenString == "" {
		protocols := c.GetHeader("Sec-WebSocket-Protocol")
		if protocols != "" {
			// Token might be passed as a protocol
			parts := strings.Split(protocols, ",")
			for _, p := range parts {
				p = strings.TrimSpace(p)
				if strings.HasPrefix(p, "token-") {
					tokenString = strings.TrimPrefix(p, "token-")
					break
				}
			}
		}
	}

	if tokenString == "" {
		return "", "", "", time.Time{}, fmt.Errorf("no authentication token provided")
	}

	// Parse and validate token
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// Verify signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(m.jwtSecret), nil
	})

	if err != nil {
		return "", "", "", time.Time{}, fmt.Errorf("invalid token: %w", err)
	}

	if !token.Valid {
		return "", "", "", time.Time{}, fmt.Errorf("token is not valid")
	}

	// Extract claims
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", "", "", time.Time{}, fmt.Errorf("invalid token claims")
	}

	// Check expiration and extract expiry time
	var tokenExpiry time.Time
	if exp, ok := claims["exp"].(float64); ok {
		tokenExpiry = time.Unix(int64(exp), 0)
		if time.Now().Unix() > int64(exp) {
			return "", "", "", time.Time{}, fmt.Errorf("token has expired")
		}
	} else {
		return "", "", "", time.Time{}, fmt.Errorf("token missing expiration")
	}

	// Extract user information
	userID, ok := claims["user_id"]
	if !ok {
		return "", "", "", time.Time{}, fmt.Errorf("token missing user_id")
	}

	institutionID, ok := claims["institution_id"]
	if !ok {
		return "", "", "", time.Time{}, fmt.Errorf("token missing institution_id")
	}

	role, ok := claims["role"]
	if !ok {
		return "", "", "", time.Time{}, fmt.Errorf("token missing role")
	}

	// Convert to strings
	userIDStr := fmt.Sprintf("%v", userID)
	institutionIDStr := fmt.Sprintf("%v", institutionID)
	roleStr := fmt.Sprintf("%v", role)

	return userIDStr, institutionIDStr, roleStr, tokenExpiry, nil
}

// AuthenticateWebSocket is a middleware that validates JWT for WebSocket connections
func (m *WebSocketAuthMiddleware) AuthenticateWebSocket() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, institutionID, role, tokenExpiry, err := m.ValidateWebSocketToken(c)
		if err != nil {
			// Send error response and close connection
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authentication failed",
				"detail": err.Error(),
			})
			c.Abort()
			return
		}

		// Store user information in context for use by handlers
		c.Set("user_id", userID)
		c.Set("institution_id", institutionID)
		c.Set("role", role)
		c.Set("token_expiry", tokenExpiry)

		c.Next()
	}
}

// GetUpgrader returns the WebSocket upgrader
func (m *WebSocketAuthMiddleware) GetUpgrader() *websocket.Upgrader {
	return &m.upgrader
}
