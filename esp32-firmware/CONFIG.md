# Configuração do Firmware ESP32 - OrthoTrack

## Credenciais Configuradas

Este firmware está configurado com as seguintes credenciais:

### WiFi
- **SSID**: `orthotrack`
- **Password**: `L1vr3999$$$`

### API Backend
- **Endpoint**: `http://localhost:8080`
- **Device ID**: `ESP32-WROOM32-001`
- **API Key**: `orthotrack-device-key-2024`

## Como Alterar as Configurações

### Opção 1: Editar platformio.ini (Recomendado)

Edite o arquivo `platformio.ini` e modifique os valores em `build_flags`:

```ini
build_flags = 
    -DWIFI_SSID=\"seu-ssid\"
    -DWIFI_PASSWORD=\"sua-senha\"
    -DAPI_ENDPOINT=\"http://seu-backend:8080\"
    -DDEVICE_ID=\"seu-device-id\"
    -DAPI_KEY=\"sua-api-key\"
```

### Opção 2: Usar Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto com:

```env
WIFI_SSID=orthotrack
WIFI_PASSWORD=L1vr3999$$$
API_ENDPOINT=http://localhost:8080
DEVICE_ID=ESP32-WROOM32-001
API_KEY=orthotrack-device-key-2024
```

Depois, modifique `platformio.ini` para usar as variáveis:

```ini
build_flags = 
    -DWIFI_SSID=\"${sysenv.WIFI_SSID}\"
    -DWIFI_PASSWORD=\"${sysenv.WIFI_PASSWORD}\"
    -DAPI_ENDPOINT=\"${sysenv.API_ENDPOINT}\"
    -DDEVICE_ID=\"${sysenv.DEVICE_ID}\"
    -DAPI_KEY=\"${sysenv.API_KEY}\"
```

## Notas Importantes

1. **Segurança**: As credenciais estão hardcoded no firmware. Para produção, considere usar:
   - ESP32 NVS (Non-Volatile Storage) com criptografia
   - WiFi Manager para configuração via web
   - Secure boot e flash encryption

2. **API Endpoint**: Certifique-se de que o backend está acessível na rede do ESP32
   - Para testes locais: `http://localhost:8080` ou `http://192.168.x.x:8080`
   - Para produção: Use HTTPS com certificado válido

3. **Device ID**: Cada dispositivo deve ter um ID único
   - Formato sugerido: `ESP32-WROOM32-XXX` onde XXX é um número sequencial
   - O Device ID deve estar cadastrado no backend

4. **API Key**: A chave deve ser válida no backend
   - Registre o dispositivo no backend antes de usar
   - A API Key é enviada no header `X-Device-API-Key`

## Verificação

Após compilar e fazer upload, verifique no monitor serial:

```
=== OrthoTrack ESP32 Firmware v3.0 ===
Inicializando MPU6050... ✅ OK
Inicializando BMP280... ✅ OK
Conectando WiFi........... ✅ Conectado!
IP: 192.168.1.100
✅ Sistema inicializado com sucesso!
```

Se a conexão WiFi falhar, verifique:
- SSID e senha estão corretos
- Rede WiFi está disponível e no alcance
- ESP32 suporta apenas WiFi 2.4GHz (não funciona com 5GHz)
