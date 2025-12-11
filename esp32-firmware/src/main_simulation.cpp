#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

// Configuração WiFi e API - Credenciais corretas do hotspot
const char* ssid = "orthotrack";
const char* password = "L1vr3999$$$";
const char* apiEndpoint = "http://72.60.50.248:8080";
const char* deviceId = "ESP32-DEMO-001";
const char* apiKey = "orthotrack-device-key-2024";

// NTP
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");

struct SensorData {
    float accelX, accelY, accelZ;
    float gyroX, gyroY, gyroZ;
    float temperature, pressure;
    bool touchDetected, movementDetected, isWearing;
    int batteryLevel;
    unsigned long timestamp;
};

const unsigned long TELEMETRY_INTERVAL = 5000;
const unsigned long HEARTBEAT_INTERVAL = 30000;
unsigned long lastTelemetry = 0, lastHeartbeat = 0;
bool isWearing = false, wifiConnected = false;

void connectWiFi();
SensorData generateSimulatedData();
void sendTelemetry(const SensorData& data);
void sendHeartbeat();
void sendUsageStateChange(bool wearing);

void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println("\n=== OrthoTrack ESP32 v3.0 (SIMULATION) ===");
    Serial.print("WiFi: ");
    Serial.println(ssid);
    
    connectWiFi();
    
    if (wifiConnected) {
        timeClient.begin();
        timeClient.setTimeOffset(-3 * 3600);
        timeClient.update();
        Serial.println("✅ Sistema OK!");
        sendHeartbeat();
    }
}

void loop() {
    if (WiFi.status() != WL_CONNECTED) {
        connectWiFi();
    }
    
    if (wifiConnected) timeClient.update();
    
    SensorData data = generateSimulatedData();
    
    unsigned long now = millis();
    if (wifiConnected && (now - lastTelemetry >= TELEMETRY_INTERVAL)) {
        sendTelemetry(data);
        lastTelemetry = now;
    }
    
    if (wifiConnected && (now - lastHeartbeat >= HEARTBEAT_INTERVAL)) {
        sendHeartbeat();
        lastHeartbeat = now;
    }
    
    delay(100);
}

void connectWiFi() {
    Serial.print("Conectando WiFi...");
    WiFi.begin(ssid, password);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println(" ✅");
        Serial.print("IP: ");
        Serial.println(WiFi.localIP());
        wifiConnected = true;
    } else {
        Serial.println(" ❌");
        wifiConnected = false;
    }
}

SensorData generateSimulatedData() {
    SensorData data = {};
    data.accelX = random(-20, 20) / 10.0;
    data.accelY = random(-20, 20) / 10.0;
    data.accelZ = 9.8 + random(-5, 5) / 10.0;
    data.gyroX = random(-10, 10) / 100.0;
    data.gyroY = random(-10, 10) / 100.0;
    data.gyroZ = random(-10, 10) / 100.0;
    data.temperature = 35.0 + random(0, 200) / 100.0;
    data.pressure = 1013.0 + random(-50, 50) / 10.0;
    
    static unsigned long lastTouch = 0;
    static bool touchState = false;
    if (millis() - lastTouch > 15000) {
        touchState = !touchState;
        lastTouch = millis();
        Serial.print("👆 Touch: ");
        Serial.println(touchState ? "ON" : "OFF");
    }
    data.touchDetected = touchState;
    
    float accelMag = sqrt(data.accelX*data.accelX + data.accelY*data.accelY + data.accelZ*data.accelZ);
    data.movementDetected = (accelMag > 1.0);
    
    bool wearing = data.touchDetected && data.temperature >= 35.0;
    if (wearing != isWearing) {
        isWearing = wearing;
        Serial.print("👤 Uso: ");
        Serial.println(isWearing ? "SIM" : "NÃO");
        if (wifiConnected) sendUsageStateChange(isWearing);
    }
    data.isWearing = isWearing;
    
    static int battery = 100;
    static unsigned long lastBatt = 0;
    if (millis() - lastBatt > 60000) {
        battery = max(20, battery - 1);
        lastBatt = millis();
    }
    data.batteryLevel = battery;
    data.timestamp = timeClient.getEpochTime();
    
    return data;
}

void sendTelemetry(const SensorData& data) {
    HTTPClient http;
    http.begin(String(apiEndpoint) + "/api/v1/devices/telemetry");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-API-Key", apiKey);
    
    DynamicJsonDocument doc(1024);
    doc["device_id"] = deviceId;
    doc["timestamp"] = data.timestamp;
    doc["status"] = "online";
    doc["battery_level"] = data.batteryLevel;
    
    JsonObject sensors = doc.createNestedObject("sensors");
    JsonObject accel = sensors.createNestedObject("accelerometer");
    accel["type"] = "accelerometer";
    JsonObject accelVal = accel.createNestedObject("value");
    accelVal["x"] = data.accelX;
    accelVal["y"] = data.accelY;
    accelVal["z"] = data.accelZ;
    accel["unit"] = "m/s²";
    
    JsonObject temp = sensors.createNestedObject("temperature");
    temp["type"] = "temperature";
    temp["value"] = data.temperature;
    temp["unit"] = "°C";
    
    doc["is_wearing"] = data.isWearing;
    doc["movement_detected"] = data.movementDetected;
    doc["touch_detected"] = data.touchDetected;
    
    String payload;
    serializeJson(doc, payload);
    
    Serial.print("📡 Telemetria... ");
    int code = http.POST(payload);
    Serial.println(code == 200 || code == 201 ? "✅" : "❌");
    http.end();
}

void sendHeartbeat() {
    HTTPClient http;
    http.begin(String(apiEndpoint) + "/api/v1/devices/status");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-API-Key", apiKey);
    
    DynamicJsonDocument doc(256);
    doc["device_id"] = deviceId;
    doc["status"] = "online";
    doc["battery_level"] = random(80, 100);
    doc["signal_strength"] = WiFi.RSSI();
    doc["timestamp"] = timeClient.getEpochTime();
    
    String payload;
    serializeJson(doc, payload);
    
    Serial.print("💓 Heartbeat... ");
    int code = http.POST(payload);
    Serial.println(code == 200 || code == 201 ? "✅" : "❌");
    http.end();
}

void sendUsageStateChange(bool wearing) {
    HTTPClient http;
    http.begin(String(apiEndpoint) + "/api/v1/devices/alerts");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-API-Key", apiKey);
    
    DynamicJsonDocument doc(512);
    doc["device_id"] = deviceId;
    doc["alert_type"] = wearing ? "usage_started" : "usage_stopped";
    doc["severity"] = "info";
    doc["message"] = wearing ? "Uso iniciado (SIM)" : "Uso parado (SIM)";
    doc["timestamp"] = timeClient.getEpochTime();
    
    String payload;
    serializeJson(doc, payload);
    
    Serial.print("🚨 Alerta... ");
    int code = http.POST(payload);
    Serial.println(code == 200 || code == 201 ? "✅" : "❌");
    http.end();
}
