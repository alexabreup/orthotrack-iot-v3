package middleware

import (
	"fmt"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"pgregory.net/rapid"
)

// Feature: realtime-monitoring, Property 28: JWT authentication
// Validates: Requirements 9.1, 9.2
// For any WebSocket connection attempt, the system should validate the provided JWT token
// and reject invalid or expired tokens

func TestProperty_JWTAuthentication(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Generate test data
		jwtSecret := rapid.String().Draw(t, "jwtSecret")
		if jwtSecret == "" {
			jwtSecret = "test-secret-key-for-testing"
		}

		userID := rapid.Uint().Draw(t, "userID")
		institutionID := rapid.Uint().Draw(t, "institutionID")
		role := rapid.SampledFrom([]string{"admin", "physician", "physiotherapist", "technician"}).Draw(t, "role")
		
		// Generate expiry time - can be past or future
		expiryOffset := rapid.Int64Range(-3600, 3600).Draw(t, "expiryOffset") // -1 hour to +1 hour
		expiry := time.Now().Add(time.Duration(expiryOffset) * time.Second)
		
		// Create middleware
		middleware := NewWebSocketAuthMiddleware(jwtSecret)

		// Create a valid token
		token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
			"user_id":        userID,
			"institution_id": institutionID,
			"role":           role,
			"exp":            expiry.Unix(),
		})

		tokenString, err := token.SignedString([]byte(jwtSecret))
		if err != nil {
			t.Fatalf("Failed to sign token: %v", err)
		}

		// Create test request with token in query parameter
		gin.SetMode(gin.TestMode)
		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)
		c.Request = httptest.NewRequest("GET", fmt.Sprintf("/ws?token=%s", tokenString), nil)

		// Validate token
		returnedUserID, returnedInstitutionID, returnedRole, returnedExpiry, err := middleware.ValidateWebSocketToken(c)

		// Property: If token is expired, validation should fail
		if time.Now().After(expiry) {
			if err == nil {
				t.Fatalf("Expected error for expired token, but got none")
			}
		} else {
			// Property: If token is valid and not expired, validation should succeed
			if err != nil {
				t.Fatalf("Expected no error for valid token, but got: %v", err)
			}

			// Property: Returned values should match the token claims
			expectedUserID := fmt.Sprintf("%d", userID)
			if returnedUserID != expectedUserID {
				t.Fatalf("Expected userID %s, got %s", expectedUserID, returnedUserID)
			}
			expectedInstitutionID := fmt.Sprintf("%d", institutionID)
			if returnedInstitutionID != expectedInstitutionID {
				t.Fatalf("Expected institutionID %s, got %s", expectedInstitutionID, returnedInstitutionID)
			}
			if returnedRole != role {
				t.Fatalf("Expected role %s, got %s", role, returnedRole)
			}
			
			// Property: Returned expiry should match token expiry (within 1 second tolerance)
			if returnedExpiry.Unix() != expiry.Unix() {
				t.Fatalf("Expected expiry %v, got %v", expiry.Unix(), returnedExpiry.Unix())
			}
		}
	})
}

// Test that invalid tokens are rejected
func TestProperty_InvalidTokenRejection(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		jwtSecret := "test-secret-key"
		middleware := NewWebSocketAuthMiddleware(jwtSecret)

		// Generate invalid token scenarios
		scenario := rapid.IntRange(0, 4).Draw(t, "scenario")

		gin.SetMode(gin.TestMode)
		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)

		switch scenario {
		case 0:
			// No token provided
			c.Request = httptest.NewRequest("GET", "/ws", nil)
		case 1:
			// Invalid token format
			invalidToken := rapid.String().Draw(t, "invalidToken")
			c.Request = httptest.NewRequest("GET", fmt.Sprintf("/ws?token=%s", invalidToken), nil)
		case 2:
			// Token signed with wrong secret
			wrongSecret := rapid.String().Draw(t, "wrongSecret")
			if wrongSecret == jwtSecret {
				wrongSecret = wrongSecret + "different"
			}
			token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
				"user_id":        1,
				"institution_id": 1,
				"role":           "admin",
				"exp":            time.Now().Add(1 * time.Hour).Unix(),
			})
			tokenString, _ := token.SignedString([]byte(wrongSecret))
			c.Request = httptest.NewRequest("GET", fmt.Sprintf("/ws?token=%s", tokenString), nil)
		case 3:
			// Token missing required claims
			token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
				"exp": time.Now().Add(1 * time.Hour).Unix(),
				// Missing user_id, institution_id, role
			})
			tokenString, _ := token.SignedString([]byte(jwtSecret))
			c.Request = httptest.NewRequest("GET", fmt.Sprintf("/ws?token=%s", tokenString), nil)
		case 4:
			// Token missing expiration
			token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
				"user_id":        1,
				"institution_id": 1,
				"role":           "admin",
				// Missing exp
			})
			tokenString, _ := token.SignedString([]byte(jwtSecret))
			c.Request = httptest.NewRequest("GET", fmt.Sprintf("/ws?token=%s", tokenString), nil)
		}

		// Validate token
		_, _, _, _, err := middleware.ValidateWebSocketToken(c)

		// Property: All invalid token scenarios should result in an error
		if err == nil {
			t.Fatalf("Expected error for invalid token scenario %d, but got none", scenario)
		}
	})
}

// Test token extraction from different sources
func TestProperty_TokenExtractionSources(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		jwtSecret := "test-secret-key"
		middleware := NewWebSocketAuthMiddleware(jwtSecret)

		userID := rapid.Uint().Draw(t, "userID")
		institutionID := rapid.Uint().Draw(t, "institutionID")
		role := rapid.SampledFrom([]string{"admin", "physician"}).Draw(t, "role")
		expiry := time.Now().Add(1 * time.Hour)

		// Create a valid token
		token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
			"user_id":        userID,
			"institution_id": institutionID,
			"role":           role,
			"exp":            expiry.Unix(),
		})

		tokenString, _ := token.SignedString([]byte(jwtSecret))

		// Test different token sources
		source := rapid.IntRange(0, 1).Draw(t, "source")

		gin.SetMode(gin.TestMode)
		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)

		switch source {
		case 0:
			// Token in query parameter
			c.Request = httptest.NewRequest("GET", fmt.Sprintf("/ws?token=%s", tokenString), nil)
		case 1:
			// Token in Authorization header
			c.Request = httptest.NewRequest("GET", "/ws", nil)
			c.Request.Header.Set("Authorization", fmt.Sprintf("Bearer %s", tokenString))
		}

		// Validate token
		returnedUserID, returnedInstitutionID, returnedRole, _, err := middleware.ValidateWebSocketToken(c)

		// Property: Token should be successfully extracted and validated from any valid source
		if err != nil {
			t.Fatalf("Expected no error for valid token from source %d, but got: %v", source, err)
		}

		// Property: Extracted values should match regardless of source
		if returnedUserID != fmt.Sprintf("%v", userID) {
			t.Fatalf("Expected userID %v, got %s", userID, returnedUserID)
		}
		if returnedInstitutionID != fmt.Sprintf("%v", institutionID) {
			t.Fatalf("Expected institutionID %v, got %s", institutionID, returnedInstitutionID)
		}
		if returnedRole != role {
			t.Fatalf("Expected role %s, got %s", role, returnedRole)
		}
	})
}
