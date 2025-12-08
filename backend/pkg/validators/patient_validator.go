package validators

import (
	"fmt"
	"regexp"
	"strings"
	"time"
)

// ValidateCPF valida CPF brasileiro
func ValidateCPF(cpf string) error {
	if cpf == "" {
		return nil // CPF é opcional
	}

	// Remove caracteres não numéricos
	cpf = regexp.MustCompile(`\D`).ReplaceAllString(cpf, "")

	if len(cpf) != 11 {
		return fmt.Errorf("CPF deve ter 11 dígitos")
	}

	// Verifica se todos os dígitos são iguais
	if strings.Count(cpf, string(cpf[0])) == 11 {
		return fmt.Errorf("CPF inválido")
	}

	// Validação dos dígitos verificadores
	var sum int
	for i := 0; i < 9; i++ {
		digit := int(cpf[i] - '0')
		sum += digit * (10 - i)
	}
	remainder := sum % 11
	digit1 := 0
	if remainder >= 2 {
		digit1 = 11 - remainder
	}

	if digit1 != int(cpf[9]-'0') {
		return fmt.Errorf("CPF inválido")
	}

	sum = 0
	for i := 0; i < 10; i++ {
		digit := int(cpf[i] - '0')
		sum += digit * (11 - i)
	}
	remainder = sum % 11
	digit2 := 0
	if remainder >= 2 {
		digit2 = 11 - remainder
	}

	if digit2 != int(cpf[10]-'0') {
		return fmt.Errorf("CPF inválido")
	}

	return nil
}

// ValidateEmail valida formato de email
func ValidateEmail(email string) error {
	if email == "" {
		return nil // Email é opcional
	}

	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(email) {
		return fmt.Errorf("email inválido")
	}

	return nil
}

// ValidatePhone valida telefone brasileiro
func ValidatePhone(phone string) error {
	if phone == "" {
		return nil // Telefone é opcional
	}

	// Remove caracteres não numéricos
	phone = regexp.MustCompile(`\D`).ReplaceAllString(phone, "")

	if len(phone) < 10 || len(phone) > 11 {
		return fmt.Errorf("telefone deve ter 10 ou 11 dígitos")
	}

	return nil
}

// ValidateGender valida gênero
func ValidateGender(gender string) error {
	if gender == "" {
		return nil // Gênero é opcional
	}

	gender = strings.ToUpper(gender)
	if gender != "M" && gender != "F" {
		return fmt.Errorf("gênero deve ser M ou F")
	}

	return nil
}

// ValidateDateOfBirth valida data de nascimento
func ValidateDateOfBirth(date *time.Time) error {
	if date == nil {
		return nil // Data é opcional
	}

	if date.After(time.Now()) {
		return fmt.Errorf("data de nascimento não pode ser no futuro")
	}

	// Verificar se não é muito antiga (mais de 150 anos)
	oldestDate := time.Now().AddDate(-150, 0, 0)
	if date.Before(oldestDate) {
		return fmt.Errorf("data de nascimento inválida")
	}

	return nil
}

// ValidateSeverityLevel valida nível de severidade
func ValidateSeverityLevel(level int) error {
	if level < 1 || level > 5 {
		return fmt.Errorf("nível de severidade deve estar entre 1 e 5")
	}
	return nil
}

// ValidatePrescriptionHours valida horas de prescrição
func ValidatePrescriptionHours(hours int) error {
	if hours < 1 || hours > 24 {
		return fmt.Errorf("horas de prescrição devem estar entre 1 e 24")
	}
	return nil
}

// ValidateDailyUsageTarget valida meta diária de uso em minutos
func ValidateDailyUsageTarget(minutes int) error {
	if minutes < 60 || minutes > 1440 {
		return fmt.Errorf("meta diária deve estar entre 60 e 1440 minutos (1 a 24 horas)")
	}
	return nil
}













