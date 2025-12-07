package validators

import (
	"fmt"
	"strings"
)

// ValidateRequired valida campo obrigatório
func ValidateRequired(value, fieldName string) error {
	if strings.TrimSpace(value) == "" {
		return fmt.Errorf("%s é obrigatório", fieldName)
	}
	return nil
}

// ValidateLength valida comprimento de string
func ValidateLength(value string, min, max int, fieldName string) error {
	length := len(strings.TrimSpace(value))
	if length < min || length > max {
		return fmt.Errorf("%s deve ter entre %d e %d caracteres", fieldName, min, max)
	}
	return nil
}

// ValidatePositiveInt valida inteiro positivo
func ValidatePositiveInt(value int, fieldName string) error {
	if value < 0 {
		return fmt.Errorf("%s deve ser um número positivo", fieldName)
	}
	return nil
}

// ValidateRange valida valor dentro de um intervalo
func ValidateRange(value, min, max int, fieldName string) error {
	if value < min || value > max {
		return fmt.Errorf("%s deve estar entre %d e %d", fieldName, min, max)
	}
	return nil
}








