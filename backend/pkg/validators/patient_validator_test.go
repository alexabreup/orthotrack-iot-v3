package validators

import (
	"testing"
	"time"
)

func TestValidateCPF(t *testing.T) {
	tests := []struct {
		name    string
		cpf      string
		wantErr  bool
	}{
		{"CPF válido", "12345678909", false},
		{"CPF inválido - dígitos iguais", "11111111111", true},
		{"CPF inválido - tamanho errado", "123456789", true},
		{"CPF vazio - opcional", "", false},
		{"CPF com formatação", "123.456.789-09", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateCPF(tt.cpf)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateCPF() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidateEmail(t *testing.T) {
	tests := []struct {
		name    string
		email   string
		wantErr bool
	}{
		{"Email válido", "test@example.com", false},
		{"Email inválido - sem @", "testexample.com", true},
		{"Email inválido - sem domínio", "test@", true},
		{"Email vazio - opcional", "", false},
		{"Email válido complexo", "user.name+tag@example.co.uk", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateEmail(tt.email)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateEmail() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidatePhone(t *testing.T) {
	tests := []struct {
		name    string
		phone   string
		wantErr bool
	}{
		{"Telefone válido 10 dígitos", "1198765432", false},
		{"Telefone válido 11 dígitos", "11987654321", false},
		{"Telefone com formatação", "(11) 98765-4321", false},
		{"Telefone inválido - muito curto", "12345", true},
		{"Telefone vazio - opcional", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidatePhone(tt.phone)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidatePhone() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidateGender(t *testing.T) {
	tests := []struct {
		name    string
		gender  string
		wantErr bool
	}{
		{"Gênero M", "M", false},
		{"Gênero F", "F", false},
		{"Gênero minúsculo", "m", false},
		{"Gênero inválido", "X", true},
		{"Gênero vazio - opcional", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateGender(tt.gender)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateGender() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidateDateOfBirth(t *testing.T) {
	now := time.Now()
	past := now.AddDate(-20, 0, 0)
	future := now.AddDate(1, 0, 0)
	tooOld := now.AddDate(-200, 0, 0)

	tests := []struct {
		name    string
		date    *time.Time
		wantErr bool
	}{
		{"Data válida", &past, false},
		{"Data no futuro", &future, true},
		{"Data muito antiga", &tooOld, true},
		{"Data nil - opcional", nil, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateDateOfBirth(tt.date)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateDateOfBirth() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidateSeverityLevel(t *testing.T) {
	tests := []struct {
		name    string
		level   int
		wantErr bool
	}{
		{"Nível válido 1", 1, false},
		{"Nível válido 5", 5, false},
		{"Nível válido 3", 3, false},
		{"Nível inválido 0", 0, true},
		{"Nível inválido 6", 6, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateSeverityLevel(tt.level)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateSeverityLevel() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}








