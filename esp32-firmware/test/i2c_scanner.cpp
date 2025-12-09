/**
 * I2C Scanner para ESP32
 * Verifica dispositivos conectados no barramento I2C
 * 
 * Uso: Compilar e fazer upload para verificar se MPU6050 e BMP280 estão conectados
 * 
 * Endereços esperados:
 * - MPU6050: 0x68 (AD0 em GND) ou 0x69 (AD0 em VCC)
 * - BMP280: 0x76 (SDO em GND) ou 0x77 (SDO em VCC)
 */

#include <Arduino.h>
#include <Wire.h>

void setup() {
    Serial.begin(115200);
    delay(2000);
    
    Serial.println("\n\n");
    Serial.println("═══════════════════════════════════════");
    Serial.println("    I2C Scanner - OrthoTrack ESP32    ");
    Serial.println("═══════════════════════════════════════");
    Serial.println();
    
    // Inicializar I2C
    Wire.begin();
    
    Serial.println("Iniciando varredura I2C...");
    Serial.println();
}

void loop() {
    byte error, address;
    int nDevices = 0;
    
    Serial.println("Procurando dispositivos I2C...");
    Serial.println("───────────────────────────────────────");
    
    for(address = 1; address < 127; address++) {
        // Tentar comunicação com o endereço
        Wire.beginTransmission(address);
        error = Wire.endTransmission();
        
        if (error == 0) {
            // Dispositivo encontrado
            Serial.print("✅ Dispositivo I2C encontrado no endereço 0x");
            if (address < 16) {
                Serial.print("0");
            }
            Serial.print(address, HEX);
            Serial.print(" (");
            Serial.print(address);
            Serial.print(")");
            
            // Identificar dispositivo conhecido
            if (address == 0x68) {
                Serial.print(" → MPU6050 (AD0=GND)");
            } else if (address == 0x69) {
                Serial.print(" → MPU6050 (AD0=VCC)");
            } else if (address == 0x76) {
                Serial.print(" → BMP280 (SDO=GND)");
            } else if (address == 0x77) {
                Serial.print(" → BMP280/BME280 (SDO=VCC)");
            } else {
                Serial.print(" → Dispositivo desconhecido");
            }
            
            Serial.println();
            nDevices++;
            
        } else if (error == 4) {
            // Erro desconhecido
            Serial.print("⚠️  Erro desconhecido no endereço 0x");
            if (address < 16) {
                Serial.print("0");
            }
            Serial.println(address, HEX);
        }
    }
    
    Serial.println("───────────────────────────────────────");
    
    if (nDevices == 0) {
        Serial.println("❌ Nenhum dispositivo I2C encontrado!");
        Serial.println();
        Serial.println("Verificar:");
        Serial.println("  • Conexões SDA (GPIO21) e SCL (GPIO22)");
        Serial.println("  • Alimentação 3.3V");
        Serial.println("  • GND comum");
        Serial.println("  • Módulos funcionando");
    } else {
        Serial.print("✅ Total de dispositivos encontrados: ");
        Serial.println(nDevices);
        Serial.println();
        
        // Verificar se os sensores esperados foram encontrados
        bool mpu6050Found = false;
        bool bmp280Found = false;
        
        for(address = 1; address < 127; address++) {
            Wire.beginTransmission(address);
            error = Wire.endTransmission();
            
            if (error == 0) {
                if (address == 0x68 || address == 0x69) {
                    mpu6050Found = true;
                }
                if (address == 0x76 || address == 0x77) {
                    bmp280Found = true;
                }
            }
        }
        
        Serial.println("Status dos sensores:");
        Serial.print("  MPU6050: ");
        Serial.println(mpu6050Found ? "✅ Encontrado" : "❌ Não encontrado");
        Serial.print("  BMP280:  ");
        Serial.println(bmp280Found ? "✅ Encontrado" : "❌ Não encontrado");
        
        if (mpu6050Found && bmp280Found) {
            Serial.println();
            Serial.println("🎉 Todos os sensores estão conectados!");
            Serial.println("   Pronto para fazer upload do firmware principal.");
        } else {
            Serial.println();
            Serial.println("⚠️  Alguns sensores não foram encontrados.");
            Serial.println("   Verificar conexões antes de continuar.");
        }
    }
    
    Serial.println();
    Serial.println("═══════════════════════════════════════");
    Serial.println("Nova varredura em 5 segundos...");
    Serial.println();
    
    delay(5000);
}
