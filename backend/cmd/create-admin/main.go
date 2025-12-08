package main

import (
	"fmt"
	"log"
	"os"

	"orthotrack-iot-v3/internal/config"
	"orthotrack-iot-v3/internal/models"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	// Carregar configuração
	cfg := config.Load()

	// Conectar ao banco de dados
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
		cfg.Database.Host,
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.Name,
		cfg.Database.Port,
		cfg.Database.SSLMode,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Gerar hash da senha
	password := "admin2025"
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("Failed to hash password: %v", err)
	}

	// Verificar se já existe uma instituição
	var institution models.Institution
	if err := db.Where("code = ?", "AACD-SP").First(&institution).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			// Criar instituição padrão
			institution = models.Institution{
				UUID:    uuid.New(),
				Name:    "AACD - Associação de Assistência à Criança Deficiente",
				Code:    "AACD-SP",
				CNPJ:    "60.945.284/0001-06",
				Address: "Av. Prof. Ascendino Reis, 724 - Vila Clementino, São Paulo - SP",
				City:    "São Paulo",
				State:   "SP",
				ZipCode: "04027-000",
				Phone:   "(11) 5576-0777",
				Email:   "contato@aacd.org.br",
				Website: "https://www.aacd.org.br",
				Type:    "hospital",
				Status:  "active",
			}
			if err := db.Create(&institution).Error; err != nil {
				log.Fatalf("Failed to create institution: %v", err)
			}
			log.Printf("✅ Instituição criada: %s (ID: %d)", institution.Name, institution.ID)
		} else {
			log.Fatalf("Failed to query institution: %v", err)
		}
	} else {
		log.Printf("📋 Instituição encontrada: %s (ID: %d)", institution.Name, institution.ID)
	}

	// Verificar se já existe usuário admin
	var adminStaff models.MedicalStaff
	email := "admin"
	if err := db.Where("email = ?", email).First(&adminStaff).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			// Criar novo usuário admin
			adminStaff = models.MedicalStaff{
				UUID:          uuid.New(),
				InstitutionID: institution.ID,
				Name:          "Administrador Sistema",
				Email:         email,
				Phone:         "(11) 5576-0777",
				Role:          "admin",
				Specialty:     "Sistema",
				Department:    "Administração",
				PasswordHash:  string(hashedPassword),
				IsActive:      true,
				Permissions:   `{"admin": true, "patients": ["read", "write"], "devices": ["read", "write"], "reports": ["read", "write"]}`,
			}
			if err := db.Create(&adminStaff).Error; err != nil {
				log.Fatalf("Failed to create admin user: %v", err)
			}
			log.Printf("✅ Usuário admin criado com sucesso!")
			log.Printf("   Email: %s", email)
			log.Printf("   Senha: %s", password)
			log.Printf("   ID: %d", adminStaff.ID)
		} else {
			log.Fatalf("Failed to query admin user: %v", err)
		}
	} else {
		// Atualizar senha do usuário existente
		adminStaff.PasswordHash = string(hashedPassword)
		adminStaff.IsActive = true
		if err := db.Save(&adminStaff).Error; err != nil {
			log.Fatalf("Failed to update admin user: %v", err)
		}
		log.Printf("✅ Senha do usuário admin atualizada com sucesso!")
		log.Printf("   Email: %s", email)
		log.Printf("   Nova senha: %s", password)
		log.Printf("   ID: %d", adminStaff.ID)
	}

	log.Println("\n🎉 Processo concluído!")
	os.Exit(0)
}







