#ifndef OTA_UPDATE_H
#define OTA_UPDATE_H

#include <Arduino.h>
#include <HTTPClient.h>
#include <Update.h>

// Configurações OTA
#define OTA_CHECK_INTERVAL 3600000  // Verificar atualizações a cada 1 hora (ms)
#define OTA_BUFFER_SIZE 1024        // Buffer para download

// Versão atual do firmware
#define FIRMWARE_VERSION "1.0.0"

// Estados do OTA
enum OTAState {
    OTA_IDLE,
    OTA_CHECKING,
    OTA_DOWNLOADING,
    OTA_INSTALLING,
    OTA_SUCCESS,
    OTA_ERROR
};

// Estrutura de informações de atualização
struct OTAUpdateInfo {
    String version;
    String url;
    size_t size;
    String checksum;
    bool isDelta;  // true se for patch delta, false se for firmware completo
};

class OTAUpdater {
private:
    OTAState currentState;
    unsigned long lastCheckTime;
    String apiEndpoint;
    String deviceId;
    String apiKey;
    OTAUpdateInfo updateInfo;
    
    // Funções privadas
    bool checkForUpdate();
    bool downloadAndInstallUpdate();
    bool downloadAndInstallDelta();
    bool downloadAndInstallFull();
    bool verifyChecksum(const String& checksum);
    void sendOTAStatus(const String& status, const String& message);
    
public:
    OTAUpdater(const String& endpoint, const String& devId, const String& key);
    
    void begin();
    void loop();
    void forceCheck();
    
    OTAState getState() { return currentState; }
    String getCurrentVersion() { return FIRMWARE_VERSION; }
    OTAUpdateInfo getUpdateInfo() { return updateInfo; }
};

#endif // OTA_UPDATE_H
