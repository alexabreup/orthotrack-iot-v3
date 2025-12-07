# 🚀 Configuração para Produção - Android Edge Node

Este guia explica como configurar o Android Edge Node para conectar ao servidor de produção.

## 📋 Servidor de Produção

- **IP**: 72.60.50.248
- **Backend API**: http://72.60.50.248:8080
- **MQTT Broker**: mqtt://72.60.50.248:1883
- **MQTT WebSocket**: ws://72.60.50.248:9001

## 🔧 Configuração

### 1. Arquivo de Ambiente

O projeto já está configurado para produção. As variáveis de ambiente estão definidas em:

- `.env.production` - Configuração de produção
- `.env.example` - Exemplo de configuração

Para usar produção, certifique-se de que o arquivo `.env` (ou `.env.production`) contém:

```env
VITE_API_BASE_URL=http://72.60.50.248:8080
VITE_MQTT_BROKER_URL=tcp://72.60.50.248:1883
```

### 2. Network Security Config

O arquivo `network_security_config.xml` já está configurado para permitir conexões HTTP para o servidor de produção (72.60.50.248).

### 3. Build para Produção

```bash
cd /home/alxp/Desktop/alexp/iot-golang/orthotrack-iot-v3/android-edge-node

# Usar configuração de produção
cp .env.production .env

# Build do projeto
npm run build

# Sincronizar com Capacitor
npm run cap:sync

# Abrir no Android Studio
npm run cap:open:android
```

### 4. Build no Android Studio

1. Abra o projeto no Android Studio
2. Selecione **Build > Build Bundle(s) / APK(s) > Build APK(s)**
3. Aguarde o build completar
4. O APK estará em `android/app/build/outputs/apk/debug/app-debug.apk`

## 📱 Instalação no Dispositivo

### Opção 1: Via ADB (Recomendado)

```bash
# Conectar dispositivo via USB
adb devices

# Instalar APK
adb install android/app/build/outputs/apk/debug/app-debug.apk
```

### Opção 2: Transferir APK

1. Copie o APK para o dispositivo
2. No dispositivo, abra o arquivo
3. Permita instalação de fontes desconhecidas
4. Instale o APK

## ✅ Verificação

### 1. Verificar Conexão com Backend

Ao abrir o app, ele deve:
- Mostrar "Backend: Online" no status
- Conectar automaticamente ao servidor
- Permitir escanear dispositivos BLE

### 2. Verificar Logs

```bash
# Ver logs do app
adb logcat | grep -i "orthotrack\|api\|http"

# Verificar conexão
adb logcat | grep -i "backend\|health"
```

### 3. Testar Funcionalidades

1. **Health Check**: O app verifica automaticamente ao iniciar
2. **Scan BLE**: Clique em "Escanear Dispositivos"
3. **Sincronização**: Dados são sincronizados automaticamente com o backend

## 🔍 Troubleshooting

### Backend não conecta

1. Verifique se o dispositivo tem internet
2. Verifique se o servidor está acessível:
   ```bash
   curl http://72.60.50.248:8080/api/v1/health
   ```
3. Verifique firewall do dispositivo (se houver)

### "Cleartext HTTP not permitted"

- O `network_security_config.xml` já está configurado
- Verifique se está referenciado no `AndroidManifest.xml`

### Build falha

```bash
# Limpar build
cd android
./gradlew clean

# Rebuild
./gradlew build
```

## 📊 Endpoints da API

O app usa os seguintes endpoints:

- `GET /api/v1/health` - Health check
- `POST /api/v1/devices/telemetry` - Enviar telemetria
- `POST /api/v1/devices/status` - Atualizar status
- `POST /api/v1/devices/alerts` - Enviar alertas
- `POST /api/v1/devices/commands/response` - Resposta de comandos

## 🔐 Autenticação

O app usa autenticação por API Key do dispositivo. A API key deve ser configurada no backend e fornecida ao dispositivo.

## 📝 Próximos Passos

1. ✅ Configuração de produção concluída
2. ⏳ Build do APK
3. ⏳ Instalação no dispositivo
4. ⏳ Teste de conectividade
5. ⏳ Teste de sincronização de dados

## 🔗 Links Úteis

- **Backend API**: http://72.60.50.248:8080
- **Swagger Docs**: http://72.60.50.248:8080/swagger/index.html
- **Health Check**: http://72.60.50.248:8080/api/v1/health


