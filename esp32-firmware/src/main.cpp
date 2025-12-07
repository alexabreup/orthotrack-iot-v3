#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_BMP280.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

// Configuração WiFi e API (definidas em platformio.ini)
#ifndef WIFI_SSID
#define WIFI_SSID "YOUR_WIFI_SSID"
#endif

#ifndef WIFI_PASSWORD  
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"
#endif

#ifndef API_ENDPOINT
#define API_ENDPOINT "https://api.orthotrack.com"
#endif

#ifndef DEVICE_ID
#define DEVICE_ID "ESP32-001"
#endif

#ifndef API_KEY
#define API_KEY "your-device-api-key"
#endif

// Sensores
Adafruit_MPU6050 mpu;
Adafruit_BMP280 bmp;

// NTP para sincronização de tempo
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");

// Configurações
const unsigned long TELEMETRY_INTERVAL = 5000; // 5 segundos
const unsigned long HEARTBEAT_INTERVAL = 30000; // 30 segundos
const float USAGE_THRESHOLD = 1.0; // m/s² para detectar uso
const int BATTERY_PIN = 35; // ADC pin para leitura de bateria

// Estados
unsigned long lastTelemetry = 0;
unsigned long lastHeartbeat = 0;
bool isWearing = false;
bool wifiConnected = false;

// Estruturas de dados
struct SensorData {
    float accelX, accelY, accelZ;
    float gyroX, gyroY, gyroZ;
    float temperature;
    float pressure;
    bool movementDetected;
    bool isWearing;
    int batteryLevel;
    unsigned long timestamp;
};

void setup() {
    Serial.begin(115200);
    Serial.println("=== OrthoTrack ESP32 Firmware v3.0 ===");
    
    // Inicializar I2C
    Wire.begin();
    
    // Inicializar sensores
    if (!initSensors()) {
        Serial.println("❌ Erro ao inicializar sensores!");
        ESP.restart();
    }
    
    // Conectar WiFi
    connectWiFi();
    
    // Sincronizar tempo
    timeClient.begin();
    timeClient.setTimeOffset(-3 * 3600); // UTC-3 (Brasil)
    
    Serial.println("✅ Sistema inicializado com sucesso!");
    
    // Enviar heartbeat inicial
    sendHeartbeat();
}

void loop() {
    unsigned long now = millis();
    
    // Manter conexão WiFi
    if (WiFi.status() != WL_CONNECTED) {
        connectWiFi();
    }
    
    // Atualizar tempo
    timeClient.update();
    
    // Ler sensores e processar dados
    SensorData data = readSensors();
    
    // Detectar uso do colete
    detectUsage(data);
    
    // Enviar telemetria
    if (now - lastTelemetry >= TELEMETRY_INTERVAL) {
        sendTelemetry(data);
        lastTelemetry = now;
    }
    
    // Enviar heartbeat
    if (now - lastHeartbeat >= HEARTBEAT_INTERVAL) {
        sendHeartbeat();
        lastHeartbeat = now;
    }
    
    // Sleep para economizar bateria
    delay(100);
}

bool initSensors() {
    Serial.print("Inicializando MPU6050... ");
    if (!mpu.begin()) {
        Serial.println("❌ Falha");
        return false;
    }
    
    // Configurar MPU6050
    mpu.setAccelerometerRange(MPU6050_RANGE_2_G);
    mpu.setGyroRange(MPU6050_RANGE_250_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    Serial.println("✅ OK");
    
    Serial.print("Inicializando BMP280... ");
    if (!bmp.begin(0x76)) {
        Serial.println("❌ Falha");
        return false;
    }
    
    // Configurar BMP280
    bmp.setSampling(Adafruit_BMP280::MODE_NORMAL,
                    Adafruit_BMP280::SAMPLING_X2,
                    Adafruit_BMP280::SAMPLING_X16,
                    Adafruit_BMP280::FILTER_X16,
                    Adafruit_BMP280::STANDBY_MS_500);
    Serial.println("✅ OK");
    
    return true;
}

void connectWiFi() {
    Serial.print("Conectando WiFi");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println(" ✅ Conectado!");
        Serial.print("IP: ");
        Serial.println(WiFi.localIP());
        wifiConnected = true;
    } else {
        Serial.println(" ❌ Falha na conexão!");
        wifiConnected = false;
    }
}

SensorData readSensors() {
    SensorData data = {};
    
    // Ler MPU6050
    sensors_event_t accel, gyro, temp;
    mpu.getEvent(&accel, &gyro, &temp);
    
    data.accelX = accel.acceleration.x;
    data.accelY = accel.acceleration.y;
    data.accelZ = accel.acceleration.z;
    data.gyroX = gyro.gyro.x;
    data.gyroY = gyro.gyro.y;
    data.gyroZ = gyro.gyro.z;
    
    // Ler BMP280
    data.temperature = bmp.readTemperature();
    data.pressure = bmp.readPressure() / 100.0F; // hPa
    
    // Detectar movimento
    float accelMagnitude = sqrt(data.accelX * data.accelX + 
                               data.accelY * data.accelY + 
                               data.accelZ * data.accelZ);
    data.movementDetected = (accelMagnitude > USAGE_THRESHOLD);
    
    // Ler nível da bateria
    data.batteryLevel = readBatteryLevel();
    
    // Timestamp
    data.timestamp = timeClient.getEpochTime();
    
    return data;
}

void detectUsage(SensorData& data) {
    // Algoritmo simples de detecção de uso
    // Em produção, usar ML mais sofisticado
    
    bool currentlyWearing = false;
    
    // Critérios para detectar uso:
    // 1. Temperatura corporal (30-40°C)
    // 2. Movimento humano normal
    // 3. Pressão consistente
    
    if (data.temperature >= 30.0 && data.temperature <= 40.0) {
        if (data.movementDetected) {
            currentlyWearing = true;
        }
    }
    
    // Filtro para evitar falsos positivos/negativos
    static int wearingCount = 0;
    if (currentlyWearing) {
        wearingCount++;
    } else {
        wearingCount = max(0, wearingCount - 1);
    }
    
    // Require 5 consecutive readings
    data.isWearing = (wearingCount >= 5);
    
    // Detectar mudança de estado
    if (data.isWearing != isWearing) {
        isWearing = data.isWearing;
        Serial.print("👤 Estado de uso: ");
        Serial.println(isWearing ? "EM USO" : "NÃO USADO");
        
        // Enviar alerta de mudança de estado
        sendUsageStateChange(isWearing);
    }
}

void sendTelemetry(const SensorData& data) {
    if (!wifiConnected) return;
    
    HTTPClient http;
    http.begin(String(API_ENDPOINT) + "/api/v1/devices/telemetry");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-API-Key", API_KEY);
    
    // Criar JSON
    DynamicJsonDocument doc(1024);
    doc["device_id"] = DEVICE_ID;
    doc["timestamp"] = data.timestamp;
    doc["status"] = "online";
    doc["battery_level"] = data.batteryLevel;
    
    // Dados dos sensores
    JsonObject sensors = doc.createNestedObject("sensors");
    
    JsonObject accel = sensors.createNestedObject("accelerometer");
    accel["type"] = "accelerometer";
    JsonObject accelValue = accel.createNestedObject("value");
    accelValue["x"] = data.accelX;
    accelValue["y"] = data.accelY;
    accelValue["z"] = data.accelZ;
    accel["unit"] = "m/s²";
    
    JsonObject gyro = sensors.createNestedObject("gyroscope");
    gyro["type"] = "gyroscope";
    JsonObject gyroValue = gyro.createNestedObject("value");
    gyroValue["x"] = data.gyroX;
    gyroValue["y"] = data.gyroY;
    gyroValue["z"] = data.gyroZ;
    gyro["unit"] = "rad/s";
    
    JsonObject temp = sensors.createNestedObject("temperature");
    temp["type"] = "temperature";
    temp["value"] = data.temperature;
    temp["unit"] = "°C";
    
    JsonObject pressure = sensors.createNestedObject("pressure");
    pressure["type"] = "pressure";
    pressure["value"] = data.pressure;
    pressure["unit"] = "hPa";
    
    // Análise de uso
    doc["is_wearing"] = data.isWearing;
    doc["movement_detected"] = data.movementDetected;
    
    String payload;
    serializeJson(doc, payload);
    
    int httpCode = http.POST(payload);
    
    if (httpCode == 200) {
        Serial.println("📡 Telemetria enviada");
    } else {
        Serial.printf("❌ Erro ao enviar telemetria: %d\n", httpCode);
        if (httpCode > 0) {
            Serial.println("Response: " + http.getString());
        }
    }
    
    http.end();
}

void sendHeartbeat() {
    if (!wifiConnected) return;
    
    HTTPClient http;
    http.begin(String(API_ENDPOINT) + "/api/v1/devices/status");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-API-Key", API_KEY);
    
    DynamicJsonDocument doc(256);
    doc["device_id"] = DEVICE_ID;
    doc["status"] = "online";
    doc["battery_level"] = readBatteryLevel();
    doc["signal_strength"] = WiFi.RSSI();
    doc["timestamp"] = timeClient.getEpochTime();
    
    String payload;
    serializeJson(doc, payload);
    
    int httpCode = http.POST(payload);
    
    if (httpCode == 200) {
        Serial.println("💓 Heartbeat enviado");
    } else {
        Serial.printf("❌ Erro no heartbeat: %d\n", httpCode);
    }
    
    http.end();
}

void sendUsageStateChange(bool wearing) {
    if (!wifiConnected) return;
    
    HTTPClient http;
    http.begin(String(API_ENDPOINT) + "/api/v1/devices/alerts");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-API-Key", API_KEY);
    
    DynamicJsonDocument doc(512);
    doc["device_id"] = DEVICE_ID;
    doc["alert_type"] = wearing ? "usage_started" : "usage_stopped";
    doc["severity"] = "info";
    doc["message"] = wearing ? "Paciente começou a usar o colete" : "Paciente parou de usar o colete";
    doc["timestamp"] = timeClient.getEpochTime();
    
    String payload;
    serializeJson(doc, payload);
    
    int httpCode = http.POST(payload);
    
    if (httpCode == 200) {
        Serial.println("🚨 Alerta de mudança de estado enviado");
    } else {
        Serial.printf("❌ Erro ao enviar alerta: %d\n", httpCode);
    }
    
    http.end();
}

int readBatteryLevel() {
    // Ler tensão da bateria via ADC
    // Assumindo divisor de tensão e bateria Li-ion (3.0V - 4.2V)
    int adcValue = analogRead(BATTERY_PIN);
    float voltage = (adcValue / 4095.0) * 3.3 * 2; // *2 para divisor de tensão
    
    // Mapear tensão para percentual (3.0V = 0%, 4.2V = 100%)
    int percentage = map(voltage * 100, 300, 420, 0, 100);
    return constrain(percentage, 0, 100);
}

// Função para enviar alertas de bateria baixa
void checkBatteryLevel() {
    int batteryLevel = readBatteryLevel();
    
    static bool lowBatteryAlerted = false;
    
    if (batteryLevel <= 20 && !lowBatteryAlerted) {
        // Enviar alerta de bateria baixa
        HTTPClient http;
        http.begin(String(API_ENDPOINT) + "/api/v1/devices/alerts");
        http.addHeader("Content-Type", "application/json");
        http.addHeader("X-Device-API-Key", API_KEY);
        
        DynamicJsonDocument doc(512);
        doc["device_id"] = DEVICE_ID;
        doc["alert_type"] = "battery_low";
        doc["severity"] = "high";
        doc["message"] = "Bateria baixa: " + String(batteryLevel) + "%";
        doc["value"] = batteryLevel;
        doc["threshold"] = 20;
        doc["timestamp"] = timeClient.getEpochTime();
        
        String payload;
        serializeJson(doc, payload);
        
        http.POST(payload);
        http.end();
        
        lowBatteryAlerted = true;
        Serial.println("🔋 Alerta de bateria baixa enviado");
    }
    
    if (batteryLevel > 30) {
        lowBatteryAlerted = false; // Reset flag
    }
}