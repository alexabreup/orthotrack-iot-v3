package validators

import (
	"testing"
)

func TestValidateDeviceID(t *testing.T) {
	tests := []struct {
		name    string
		deviceID string
		wantErr bool
	}{
		{"DeviceID válido", "ESP32-001", false},
		{"DeviceID muito curto", "AB", true},
		{"DeviceID muito longo", string(make([]byte, 51)), true},
		{"DeviceID com caracteres inválidos", "ESP32@001", true},
		{"DeviceID vazio", "", true},
		{"DeviceID com underscore", "ESP32_001", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateDeviceID(tt.deviceID)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateDeviceID() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidateMacAddress(t *testing.T) {
	tests := []struct {
		name    string
		mac     string
		wantErr bool
	}{
		{"MAC válido com dois pontos", "AA:BB:CC:DD:EE:FF", false},
		{"MAC válido com hífen", "AA-BB-CC-DD-EE-FF", false},
		{"MAC inválido - formato errado", "AA:BB:CC:DD:EE", true},
		{"MAC inválido - caracteres inválidos", "AA:BB:CC:DD:EE:GG", true},
		{"MAC vazio", "", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateMacAddress(tt.mac)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateMacAddress() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidateBatteryLevel(t *testing.T) {
	valid := 50
	invalidLow := -1
	invalidHigh := 101

	tests := []struct {
		name    string
		level   *int
		wantErr bool
	}{
		{"Nível válido", &valid, false},
		{"Nível mínimo", intPtr(0), false},
		{"Nível máximo", intPtr(100), false},
		{"Nível muito baixo", &invalidLow, true},
		{"Nível muito alto", &invalidHigh, true},
		{"Nível nil - opcional", nil, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateBatteryLevel(tt.level)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateBatteryLevel() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func intPtr(i int) *int {
	return &i
}








