# Guia para Rodar Android Edge Node em Localhost

Este guia explica como configurar e executar o aplicativo Android Edge Node conectado ao backend rodando em localhost.

## 📋 Pré-requisitos

1. **Android Studio** instalado (versão mais recente recomendada)
2. **Backend Go** rodando em localhost (porta 8080)
3. **MQTT Broker** rodando (porta 1883) - opcional
4. **Emulador Android** ou **Dispositivo Físico** conectado

## 🔧 Configuração

### Opção 1: Emulador Android (Recomendado para Desenvolvimento)

O emulador Android usa um IP especial para acessar o localhost da máquina host:

- **IP do Emulador**: `10.0.2.2` (mapeia para `127.0.0.1` da máquina host)

O arquivo `app/build.gradle` já está configurado com:
```gradle
buildConfigField "String", "API_BASE_URL", "\"http://10.0.2.2:8080\""
buildConfigField "String", "MQTT_BROKER_URL", "\"tcp://10.0.2.2:1883\""
```

### Opção 2: Dispositivo Físico

Para usar um dispositivo físico, você precisa:

1. **Descobrir o IP da sua máquina na rede local**:
   ```bash
   # Linux/Mac
   hostname -I
   # ou
   ip addr show | grep "inet " | grep -v 127.0.0.1
   
   # Windows
   ipconfig
   # Procure por "IPv4 Address" na sua interface de rede
   ```

2. **Atualizar o build.gradle** com seu IP:
   ```gradle
   buildConfigField "String", "API_BASE_URL", "\"http://SEU_IP_AQUI:8080\""
   buildConfigField "String", "MQTT_BROKER_URL", "\"tcp://SEU_IP_AQUI:1883\""
   ```

3. **Garantir que o dispositivo e a máquina estão na mesma rede WiFi**

### Opção 3: ADB Port Forwarding (Alternativa)

Você pode usar `adb reverse` para fazer port forwarding:

```bash
# Redirecionar porta 8080 do dispositivo para localhost:8080
adb reverse tcp:8080 tcp:8080

# Redirecionar porta 1883 (MQTT)
adb reverse tcp:1883 tcp:1883
```

Depois, no `build.gradle`, use:
```gradle
buildConfigField "String", "API_BASE_URL", "\"http://127.0.0.1:8080\""
```

## 🚀 Passos para Executar

### 1. Iniciar o Backend

```bash
cd /home/alxp/Desktop/alexp/iot-golang/orthotrack-iot-v3/backend
go run cmd/api/main.go
```

O backend deve estar rodando em `http://localhost:8080`

### 2. Verificar se o Backend está Acessível

```bash
# Testar health check
curl http://localhost:8080/api/v1/health

# Deve retornar:
# {"status":"healthy","timestamp":"...","version":"3.0.0"}
```

### 3. Abrir o Projeto no Android Studio

```bash
cd /home/alxp/Desktop/alexp/iot-golang/orthotrack-iot-v3/android-edge-node
# Abrir Android Studio e selecionar esta pasta
```

Ou via linha de comando:
```bash
studio /home/alxp/Desktop/alexp/iot-golang/orthotrack-iot-v3/android-edge-node
```

### 4. Configurar o Emulador/Dispositivo

#### Emulador:
1. Abra o **AVD Manager** no Android Studio
2. Crie um novo emulador ou use um existente
3. **Requisitos mínimos**:
   - API Level 23+ (Android 6.0)
   - RAM: 2GB+
   - Storage: 2GB+

#### Dispositivo Físico:
1. Ative **Modo Desenvolvedor** no dispositivo
2. Ative **Depuração USB**
3. Conecte via USB
4. Autorize o computador quando solicitado

### 5. Build e Run

#### Via Android Studio:
1. Clique em **Run** (▶️) ou pressione `Shift + F10`
2. Selecione o emulador/dispositivo
3. Aguarde o build e instalação

#### Via Linha de Comando:
```bash
cd android-edge-node

# Build debug
./gradlew assembleDebug

# Instalar no dispositivo conectado
./gradlew installDebug

# Ou executar diretamente
./gradlew installDebug && adb shell am start -n com.orthotrack.edgenode/.MainActivity
```

## 🔍 Verificar Conexão

### 1. Verificar Logs do App

```bash
# Ver logs do Android
adb logcat | grep -i "orthotrack\|edgenode\|api"

# Ou filtrar por tag específica
adb logcat -s EdgeNode:V API:V
```

### 2. Testar Conexão com Backend

No app, tente fazer login ou qualquer requisição. Verifique os logs:

```bash
# Logs do backend
cd backend
# Os logs devem mostrar requisições chegando
```

### 3. Verificar Network Security Config

Se estiver usando HTTP (não HTTPS) em localhost, você precisa configurar o `network_security_config.xml`:

Crie o arquivo: `app/src/main/res/xml/network_security_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

E referencie no `AndroidManifest.xml`:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

## 🐛 Troubleshooting

### Problema: "Connection refused" ou "Network error"

**Soluções**:
1. Verifique se o backend está rodando: `curl http://localhost:8080/api/v1/health`
2. Verifique o firewall (pode estar bloqueando conexões)
3. Para emulador, use `10.0.2.2` em vez de `localhost`
4. Para dispositivo físico, verifique se estão na mesma rede WiFi

### Problema: "Cleartext HTTP traffic not permitted"

**Solução**: Configure o `network_security_config.xml` como mostrado acima.

### Problema: App não encontra o backend

**Soluções**:
1. Verifique o IP configurado no `build.gradle`
2. Teste a conexão manualmente:
   ```bash
   # No emulador/dispositivo, via adb shell
   adb shell
   curl http://10.0.2.2:8080/api/v1/health
   ```

### Problema: Build falha

**Soluções**:
1. Sincronize o projeto: `File > Sync Project with Gradle Files`
2. Limpe o build: `Build > Clean Project`
3. Rebuild: `Build > Rebuild Project`
4. Verifique se todas as dependências foram baixadas

## 📱 Estrutura do Projeto

```
android-edge-node/
├── app/
│   ├── build.gradle          # Configurações de build
│   ├── src/
│   │   └── main/
│   │       ├── java/...      # Código Kotlin/Java
│   │       ├── res/          # Recursos (layouts, valores)
│   │       └── AndroidManifest.xml
│   └── ...
├── build.gradle              # Build root
└── gradle/                   # Wrapper Gradle
```

## 🔐 Configuração de API Key

O app precisa de uma API key para autenticar com o backend. Configure no código ou via SharedPreferences:

```kotlin
// Exemplo de configuração
val apiKey = "your-device-api-key"
```

## 📊 Monitoramento

### Ver Requisições HTTP

O app usa OkHttp com logging interceptor. Para ver as requisições:

```bash
adb logcat | grep -i "okhttp"
```

### Ver Logs do Backend

```bash
cd backend
# Os logs aparecerão no console onde você rodou o backend
```

## 🎯 Próximos Passos

1. Implementar a comunicação BLE com ESP32
2. Implementar sincronização de dados
3. Implementar armazenamento offline
4. Adicionar testes unitários e de integração

## 📚 Referências

- [Android Emulator Networking](https://developer.android.com/studio/run/emulator-networking)
- [ADB Reverse](https://developer.android.com/studio/command-line/adb#reverse)
- [Network Security Config](https://developer.android.com/training/articles/security-config)

---

**Nota**: Este projeto ainda está em desenvolvimento. Algumas funcionalidades podem não estar completamente implementadas.






