package validators

import (
	"fmt"
	"regexp"
	"strings"
)

// ValidateDeviceID valida ID do dispositivo
func ValidateDeviceID(deviceID string) error {
	if deviceID == "" {
		return fmt.Errorf("device_id é obrigatório")
	}

	if len(deviceID) < 3 || len(deviceID) > 50 {
		return fmt.Errorf("device_id deve ter entre 3 e 50 caracteres")
	}

	// Apenas alfanuméricos, hífen e underscore
	matched, _ := regexp.MatchString(`^[a-zA-Z0-9_-]+$`, deviceID)
	if !matched {
		return fmt.Errorf("device_id contém caracteres inválidos")
	}

	return nil
}

// ValidateMacAddress valida endereço MAC
func ValidateMacAddress(mac string) error {
	if mac == "" {
		return fmt.Errorf("mac_address é obrigatório")
	}

	// Formato: XX:XX:XX:XX:XX:XX
	macRegex := regexp.MustCompile(`^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$`)
	if !macRegex.MatchString(mac) {
		return fmt.Errorf("mac_address deve estar no formato XX:XX:XX:XX:XX:XX")
	}

	return nil
}

// ValidateSerialNumber valida número de série
func ValidateSerialNumber(serial string) error {
	if serial == "" {
		return fmt.Errorf("serial_number é obrigatório")
	}

	if len(serial) < 3 || len(serial) > 100 {
		return fmt.Errorf("serial_number deve ter entre 3 e 100 caracteres")
	}

	return nil
}

// ValidateBatteryLevel valida nível de bateria
func ValidateBatteryLevel(level *int) error {
	if level == nil {
		return nil // Bateria é opcional
	}

	if *level < 0 || *level > 100 {
		return fmt.Errorf("nível de bateria deve estar entre 0 e 100")
	}

	return nil
}

// ValidateSignalStrength valida força do sinal (RSSI)
func ValidateSignalStrength(strength *int) error {
	if strength == nil {
		return nil // Sinal é opcional
	}

	if *strength < -120 || *strength > 0 {
		return fmt.Errorf("força do sinal (RSSI) deve estar entre -120 e 0")
	}

	return nil
}

// ValidateDeviceStatus valida status do dispositivo
func ValidateDeviceStatus(status string) error {
	if status == "" {
		return nil // Status pode ter default
	}

	validStatuses := []string{"online", "offline", "maintenance", "active", "inactive", "error", "configuring", "updating"}
	status = strings.ToLower(status)

	for _, valid := range validStatuses {
		if status == valid {
			return nil
		}
	}

	return fmt.Errorf("status inválido. Valores válidos: %v", validStatuses)
}








