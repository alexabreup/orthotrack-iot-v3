# 🚀 Quick Start - Android Edge Node Localhost

## Passos Rápidos

### 1. Iniciar o Backend

```bash
cd /home/alxp/Desktop/alexp/iot-golang/orthotrack-iot-v3/backend
go run cmd/api/main.go
```

O backend deve estar rodando em `http://localhost:8080`

### 2. Executar Script de Setup

```bash
cd /home/alxp/Desktop/alexp/iot-golang/orthotrack-iot-v3/android-edge-node
./RUN_LOCALHOST.sh
```

Este script irá:
- ✅ Verificar se o backend está rodando
- ✅ Configurar port forwarding (se usar ADB)
- ✅ Mostrar o IP da sua máquina

### 3. Abrir no Android Studio

```bash
# Via linha de comando (se tiver studio no PATH)
studio /home/alxp/Desktop/alexp/iot-golang/orthotrack-iot-v3/android-edge-node

# Ou abra o Android Studio e selecione a pasta
```

### 4. Build e Run

No Android Studio:
1. Clique em **Run** (▶️) ou `Shift + F10`
2. Selecione o emulador/dispositivo
3. Aguarde o build e instalação

## 📱 Configurações

### Para Emulador (Padrão)
O `build.gradle` já está configurado com `10.0.2.2` que funciona automaticamente.

### Para Dispositivo Físico
1. Certifique-se que o dispositivo está na mesma rede WiFi
2. Atualize o `build.gradle` com seu IP:
   ```gradle
   buildConfigField "String", "API_BASE_URL", "\"http://192.168.15.10:8080\""
   ```
3. Rebuild o projeto

## 🔍 Verificar se Funcionou

### Testar Conexão

```bash
# Ver logs do app
adb logcat | grep -i "orthotrack\|api\|http"

# Testar health check do backend
curl http://localhost:8080/api/v1/health
```

### Verificar no App
O app deve conseguir se conectar ao backend. Verifique os logs para confirmar.

## ⚠️ Problemas Comuns

### "Connection refused"
- Verifique se o backend está rodando
- Verifique o firewall
- Para emulador: use `10.0.2.2`
- Para dispositivo: use o IP da máquina na rede

### "Cleartext HTTP not permitted"
- O `network_security_config.xml` já está configurado
- Verifique se está referenciado no `AndroidManifest.xml`

### Build falha
```bash
./gradlew clean
./gradlew build
```

## 📚 Documentação Completa

Veja `README_LOCALHOST.md` para documentação detalhada.






