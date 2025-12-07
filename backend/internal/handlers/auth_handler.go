package handlers

import (
	"net/http"
	"time"

	"orthotrack-iot-v3/internal/config"
	"orthotrack-iot-v3/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// Login godoc
// @Summary Autenticar usuário
// @Description Realiza login e retorna token JWT
// @Tags auth
// @Accept json
// @Produce json
// @Param credentials body LoginRequest true "Credenciais de login"
// @Success 200 {object} LoginResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /auth/login [post]

type AuthHandler struct {
	db  *gorm.DB
	cfg *config.Config
}

func NewAuthHandler(db *gorm.DB, cfg *config.Config) *AuthHandler {
	return &AuthHandler{
		db:  db,
		cfg: cfg,
	}
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required"` // Aceita qualquer string (email ou username)
	Password string `json:"password" binding:"required,min=6"`
}

type LoginResponse struct {
	Token        string           `json:"token"`
	ExpiresAt    time.Time        `json:"expires_at"`
	User         *UserResponse    `json:"user"`
}

type UserResponse struct {
	ID            uint   `json:"id"`
	UUID          string `json:"uuid"`
	Name          string `json:"name"`
	Email         string `json:"email"`
	Role          string `json:"role"`
	InstitutionID uint   `json:"institution_id"`
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Buscar usuário
	var staff models.MedicalStaff
	if err := h.db.Where("email = ? AND is_active = ?", req.Email, true).First(&staff).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Verificar senha
	if err := bcrypt.CompareHashAndPassword([]byte(staff.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// Atualizar último login
	now := time.Now()
	staff.LastLogin = &now
	h.db.Save(&staff)

	// Gerar token JWT
	token, expiresAt, err := h.generateToken(&staff)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, LoginResponse{
		Token:     token,
		ExpiresAt: expiresAt,
		User: &UserResponse{
			ID:            staff.ID,
			UUID:          staff.UUID.String(),
			Name:          staff.Name,
			Email:         staff.Email,
			Role:          staff.Role,
			InstitutionID: staff.InstitutionID,
		},
	})
}

func (h *AuthHandler) generateToken(staff *models.MedicalStaff) (string, time.Time, error) {
	expiresAt := time.Now().Add(time.Duration(h.cfg.JWT.ExpireHours) * time.Hour)

	claims := jwt.MapClaims{
		"user_id":       staff.ID,
		"institution_id": staff.InstitutionID,
		"email":         staff.Email,
		"role":          staff.Role,
		"exp":           expiresAt.Unix(),
		"iat":           time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(h.cfg.JWT.Secret))
	if err != nil {
		return "", time.Time{}, err
	}

	return tokenString, expiresAt, nil
}

