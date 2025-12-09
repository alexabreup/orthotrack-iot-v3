#include "ota_update.h"
#include <esp_ota_ops.h>
#include <esp_partition.h>
#include <mbedtls/md5.h>

OTAUpdater::OTAUpdater(const String& endpoint, const String& devId, const String& key) {
    apiEndpoint = endpoint;
    deviceId = devId;
    apiKey = key;
    currentState = OTA_IDLE;
    lastCheckTime = 0;
}

void OTAUpdater::begin() {
    Serial.println("🔄 OTA Updater inicializado");
    Serial.print("📦 Versão atual do firmware: ");
    Serial.println(FIRMWARE_VERSION);
    
    // Obter informações da partição atual
    const esp_partition_t* running = esp_ota_get_running_partition();
    if (running) {
        Serial.print("🗂️  Partição em execução: ");
        Serial.println(running->label);
    }
}

void OTAUpdater::loop() {
    unsigned long now = millis();
    
    // Verificar atualizações periodicamente
    if (currentState == OTA_IDLE && (now - lastCheckTime >= OTA_CHECK_INTERVAL)) {
        checkForUpdate();
        lastCheckTime = now;
    }
}

void OTAUpdater::forceCheck() {
    Serial.println("🔍 Verificação manual de atualização solicitada");
    checkForUpdate();
}

bool OTAUpdater::checkForUpdate() {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("❌ WiFi não conectado, pulando verificação OTA");
        return false;
    }
    
    currentState = OTA_CHECKING;
    Serial.println("🔍 Verificando atualizações disponíveis...");
    
    HTTPClient http;
    String url = apiEndpoint + "/api/v1/firmware/check-update";
    
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-API-Key", apiKey);
    
    // Criar payload JSON
    String payload = "{";
    payload += "\"device_id\":\"" + deviceId + "\",";
    payload += "\"current_version\":\"" + String(FIRMWARE_VERSION) + "\",";
    payload += "\"hardware\":\"ESP32-WROOM-32\"";
    payload += "}";
    
    int httpCode = http.POST(payload);
    
    if (httpCode == 200) {
        String response = http.getString();
        Serial.println("📥 Resposta do servidor: " + response);
        
        // Parse JSON response (simplificado - em produção use ArduinoJson)
        // Formato esperado: {"update_available":true,"version":"1.1.0","url":"...","size":123456,"checksum":"...","is_delta":true}
        
        if (response.indexOf("\"update_available\":true") > 0) {
            Serial.println("🆕 Atualização disponível!");
            
            // Extrair informações (parsing simplificado)
            int versionStart = response.indexOf("\"version\":\"") + 11;
            int versionEnd = response.indexOf("\"", versionStart);
            updateInfo.version = response.substring(versionStart, versionEnd);
            
            int urlStart = response.indexOf("\"url\":\"") + 7;
            int urlEnd = response.indexOf("\"", urlStart);
            updateInfo.url = response.substring(urlStart, urlEnd);
            
            int sizeStart = response.indexOf("\"size\":") + 7;
            int sizeEnd = response.indexOf(",", sizeStart);
            updateInfo.size = response.substring(sizeStart, sizeEnd).toInt();
            
            int checksumStart = response.indexOf("\"checksum\":\"") + 12;
            int checksumEnd = response.indexOf("\"", checksumStart);
            updateInfo.checksum = response.substring(checksumStart, checksumEnd);
            
            updateInfo.isDelta = response.indexOf("\"is_delta\":true") > 0;
            
            Serial.println("📦 Nova versão: " + updateInfo.version);
            Serial.println("📏 Tamanho: " + String(updateInfo.size) + " bytes");
            Serial.println("🔐 Checksum: " + updateInfo.checksum);
            Serial.println("🔄 Tipo: " + String(updateInfo.isDelta ? "Delta Patch" : "Firmware Completo"));
            
            // Iniciar download e instalação
            http.end();
            return downloadAndInstallUpdate();
        } else {
            Serial.println("✅ Firmware já está atualizado");
            currentState = OTA_IDLE;
        }
    } else if (httpCode == 204) {
        Serial.println("✅ Nenhuma atualização disponível");
        currentState = OTA_IDLE;
    } else {
        Serial.printf("❌ Erro ao verificar atualização: HTTP %d\n", httpCode);
        if (httpCode > 0) {
            Serial.println("Resposta: " + http.getString());
        }
        currentState = OTA_ERROR;
    }
    
    http.end();
    return false;
}

bool OTAUpdater::downloadAndInstallUpdate() {
    if (updateInfo.isDelta) {
        Serial.println("🔄 Iniciando atualização Delta OTA...");
        return downloadAndInstallDelta();
    } else {
        Serial.println("📦 Iniciando atualização de firmware completo...");
        return downloadAndInstallFull();
    }
}

bool OTAUpdater::downloadAndInstallDelta() {
    // NOTA: Delta OTA requer biblioteca esp_delta_ota da Espressif
    // Para Arduino, vamos usar atualização completa por enquanto
    // Em produção com ESP-IDF, use: esp_delta_ota_begin(), esp_delta_ota_write(), esp_delta_ota_end()
    
    Serial.println("⚠️  Delta OTA não implementado no Arduino Framework");
    Serial.println("📦 Fazendo fallback para atualização completa...");
    
    // Notificar backend que delta não é suportado
    sendOTAStatus("delta_not_supported", "Falling back to full update");
    
    return downloadAndInstallFull();
}

bool OTAUpdater::downloadAndInstallFull() {
    currentState = OTA_DOWNLOADING;
    
    HTTPClient http;
    http.begin(updateInfo.url);
    http.addHeader("X-Device-API-Key", apiKey);
    
    int httpCode = http.GET();
    
    if (httpCode != 200) {
        Serial.printf("❌ Erro ao baixar firmware: HTTP %d\n", httpCode);
        currentState = OTA_ERROR;
        sendOTAStatus("download_failed", "HTTP error: " + String(httpCode));
        http.end();
        return false;
    }
    
    int contentLength = http.getSize();
    Serial.printf("📥 Baixando firmware: %d bytes\n", contentLength);
    
    if (contentLength <= 0) {
        Serial.println("❌ Tamanho de conteúdo inválido");
        currentState = OTA_ERROR;
        sendOTAStatus("download_failed", "Invalid content length");
        http.end();
        return false;
    }
    
    // Iniciar atualização OTA
    if (!Update.begin(contentLength)) {
        Serial.println("❌ Não há espaço suficiente para OTA");
        Update.printError(Serial);
        currentState = OTA_ERROR;
        sendOTAStatus("install_failed", "Not enough space");
        http.end();
        return false;
    }
    
    currentState = OTA_INSTALLING;
    Serial.println("📦 Instalando atualização...");
    
    // Download e escrita
    WiFiClient* stream = http.getStreamPtr();
    uint8_t buffer[OTA_BUFFER_SIZE];
    size_t written = 0;
    size_t lastProgress = 0;
    
    while (http.connected() && (written < contentLength)) {
        size_t available = stream->available();
        
        if (available) {
            int bytesRead = stream->readBytes(buffer, min(available, sizeof(buffer)));
            
            if (bytesRead > 0) {
                size_t bytesWritten = Update.write(buffer, bytesRead);
                
                if (bytesWritten != bytesRead) {
                    Serial.println("❌ Erro ao escrever firmware");
                    Update.printError(Serial);
                    currentState = OTA_ERROR;
                    sendOTAStatus("install_failed", "Write error");
                    http.end();
                    return false;
                }
                
                written += bytesWritten;
                
                // Mostrar progresso a cada 10%
                size_t progress = (written * 100) / contentLength;
                if (progress >= lastProgress + 10) {
                    Serial.printf("📊 Progresso: %d%%\n", progress);
                    lastProgress = progress;
                }
            }
        }
        
        delay(1);
    }
    
    Serial.println("📊 Progresso: 100%");
    
    // Finalizar atualização
    if (Update.end(true)) {
        Serial.println("✅ Atualização instalada com sucesso!");
        Serial.printf("📦 Versão instalada: %s\n", updateInfo.version.c_str());
        
        currentState = OTA_SUCCESS;
        sendOTAStatus("success", "Update installed: " + updateInfo.version);
        
        http.end();
        
        Serial.println("🔄 Reiniciando em 5 segundos...");
        delay(5000);
        ESP.restart();
        
        return true;
    } else {
        Serial.println("❌ Erro ao finalizar atualização");
        Update.printError(Serial);
        currentState = OTA_ERROR;
        sendOTAStatus("install_failed", "Finalization error");
        http.end();
        return false;
    }
}

bool OTAUpdater::verifyChecksum(const String& checksum) {
    // Implementar verificação MD5/SHA256 se necessário
    // Por enquanto, retorna true
    return true;
}

void OTAUpdater::sendOTAStatus(const String& status, const String& message) {
    if (WiFi.status() != WL_CONNECTED) {
        return;
    }
    
    HTTPClient http;
    String url = apiEndpoint + "/api/v1/firmware/update-status";
    
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-API-Key", apiKey);
    
    String payload = "{";
    payload += "\"device_id\":\"" + deviceId + "\",";
    payload += "\"current_version\":\"" + String(FIRMWARE_VERSION) + "\",";
    payload += "\"status\":\"" + status + "\",";
    payload += "\"message\":\"" + message + "\"";
    payload += "}";
    
    int httpCode = http.POST(payload);
    
    if (httpCode == 200) {
        Serial.println("📤 Status OTA enviado ao servidor");
    } else {
        Serial.printf("⚠️  Erro ao enviar status OTA: HTTP %d\n", httpCode);
    }
    
    http.end();
}
