# OrthoTrack ESP32 Firmware

Firmware para dispositivos ESP32-WROOM-32 do sistema OrthoTrack IoT Platform v3.

## 📋 Visão Geral

Este firmware coleta dados de sensores (MPU6050 e BMP280), processa localmente para detectar uso do colete ortopédico, e envia telemetria via WiFi/HTTPS para o backend.

### Funcionalidades

- ✅ Conexão WiFi automática com reconexão
- ✅ Leitura de sensores MPU6050 (acelerômetro + giroscópio)
- ✅ Leitura de sensor BMP280 (temperatura + pressão)
- ✅ Detecção inteligente de uso do colete
- ✅ Envio de telemetria a cada 5 segundos
- ✅ Heartbeat a cada 30 segundos
- ✅ Monitoramento de bateria
- ✅ Alertas de mudança de estado
- ✅ Sincronização de tempo via NTP
- ✅ **Atualização OTA (Over-The-Air)** com suporte a Delta Patches

## 🔧 Pré-requisitos

### Software

- **PlatformIO Core** ou **PlatformIO IDE** (extensão VS Code)
  - Instalação: https://platformio.org/install
- **Drivers USB** para ESP32:
  - CP210x: https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
  - CH340: http://www.wch.cn/downloads/CH341SER_ZIP.html
- **Git** (opcional, para clonar o repositório)

### Hardware

- ESP32-WROOM-32 development board
- Sensor MPU6050 (acelerômetro + giroscópio)
- Sensor BMP280 (temperatura + pressão)
- Cabo USB (com suporte a dados)
- Breadboard e jumper wires (para prototipagem)
- Bateria Li-ion 3.7V (opcional)

### Rede

- Rede WiFi 2.4GHz (ESP32 não suporta 5GHz)
- Backend OrthoTrack acessível na rede

## 🚀 Quick Start

### 1. Configuração

As credenciais já estão configuradas em `platformio.ini`:

```ini
WIFI_SSID: orthotrack
WIFI_PASSWORD: L1vr3999$$$
API_ENDPOINT: http://localhost:8080
DEVICE_ID: ESP32-WROOM32-001
API_KEY: orthotrack-device-key-2024
```

**Para usar variáveis de ambiente** (opcional):

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar .env com suas credenciais
nano .env
```

### 2. Conexão do Hardware

Conecte os sensores ao ESP32 via I2C:

**MPU6050:**
- VCC → 3.3V
- GND → GND
- SDA → GPIO21
- SCL → GPIO22

**BMP280:**
- VCC → 3.3V
- GND → GND
- SDA → GPIO21 (mesmo barramento)
- SCL → GPIO22 (mesmo barramento)

**Bateria (opcional):**
- Positivo → Divisor de tensão → GPIO35
- Negativo → GND

### 3. Compilação

```bash
cd esp32-firmware
pio run
```

Saída esperada:
```
Processing esp32dev (platform: espressif32; board: esp32dev; framework: arduino)
...
Building .pio/build/esp32dev/firmware.bin
SUCCESS
```

### 4. Upload

Conecte o ESP32 via USB e execute:

```bash
pio run --target upload
```

**Dica:** Se o upload falhar, pressione e segure o botão BOOT no ESP32 durante o upload.

### 5. Monitoramento

Abra o monitor serial para ver os logs:

```bash
pio device monitor
```

Saída esperada:
```
=== OrthoTrack ESP32 Firmware v3.0 ===
Inicializando MPU6050... ✅ OK
Inicializando BMP280... ✅ OK
Conectando WiFi........... ✅ Conectado!
IP: 192.168.1.100
✅ Sistema inicializado com sucesso!
💓 Heartbeat enviado
📡 Telemetria enviada
```

## 📝 Comandos Úteis

```bash
# Compilar
pio run

# Upload
pio run --target upload

# Monitor serial
pio device monitor

# Compilar + Upload + Monitor (tudo de uma vez)
pio run --target upload && pio device monitor

# Limpar build
pio run --target clean

# Listar portas seriais disponíveis
pio device list

# Upload em porta específica
pio run --target upload --upload-port COM3  # Windows
pio run --target upload --upload-port /dev/ttyUSB0  # Linux
```

## 🔍 Verificação

### Checklist de Funcionamento

- [ ] Firmware compila sem erros
- [ ] Upload bem-sucedido
- [ ] Mensagem de startup aparece no serial
- [ ] MPU6050 inicializa (✅ OK)
- [ ] BMP280 inicializa (✅ OK)
- [ ] WiFi conecta (✅ Conectado!)
- [ ] IP é exibido
- [ ] Heartbeat enviado a cada 30s
- [ ] Telemetria enviada a cada 5s
- [ ] Backend recebe os dados

### Verificar no Backend

1. Acesse o dashboard do backend
2. Verifique se o dispositivo aparece como "online"
3. Confirme que os dados de telemetria estão sendo recebidos
4. Verifique os logs do backend para autenticação

## 🐛 Troubleshooting

### Compilação

**Erro: "Platform 'espressif32' not found"**
```bash
pio platform install espressif32
```

**Erro: "Library not found"**
```bash
pio lib install
```

### Upload

**Erro: "Serial port not found"**
- Verifique se o cabo USB suporta dados (não apenas carga)
- Instale os drivers USB (CP210x ou CH340)
- Verifique se o ESP32 está conectado: `pio device list`

**Erro: "Failed to connect"**
- Pressione e segure o botão BOOT durante o upload
- Tente reduzir a velocidade: `upload_speed = 115200` em platformio.ini
- Verifique se outra aplicação está usando a porta serial

### WiFi

**Não conecta ao WiFi**
- Verifique SSID (case-sensitive)
- Confirme a senha
- Certifique-se de que é rede 2.4GHz (não 5GHz)
- Verifique alcance do sinal
- Tente reiniciar o ESP32

**Conecta mas perde conexão**
- Verifique estabilidade da rede
- Aumente o sinal WiFi
- Verifique se há muitos dispositivos na rede

### Sensores

**MPU6050 não detectado**
- Verifique conexões I2C (SDA, SCL)
- Confirme alimentação (3.3V)
- Teste endereço I2C: pode ser 0x68 ou 0x69
- Use um I2C scanner para detectar

**BMP280 não detectado**
- Verifique conexões I2C
- Confirme alimentação (3.3V)
- Teste endereço I2C: pode ser 0x76 ou 0x77

### Backend

**HTTP 401 Unauthorized**
- API Key inválida ou não configurada no backend
- Verifique se o dispositivo está registrado

**HTTP 404 Not Found**
- Device ID não existe no banco de dados
- Registre o dispositivo no backend primeiro

**HTTP 400 Bad Request**
- Payload JSON inválido
- Verifique logs do backend para detalhes

**Sem resposta do backend**
- Verifique se o backend está rodando
- Confirme que o endpoint está correto
- Teste conectividade: `ping <backend-ip>`
- Verifique firewall

## 🔄 Atualizações OTA (Over-The-Air)

O firmware suporta atualizações remotas sem necessidade de conexão física!

### Verificação Automática

O dispositivo verifica atualizações automaticamente a cada 1 hora.

### Criar Patch Delta

```bash
# Instalar dependências
pip install -r tools/requirements.txt

# Criar patch entre versões
python tools/create_delta_patch.py \
  --chip esp32 \
  --base firmware_v1.0.0.bin \
  --new firmware_v1.1.0.bin \
  --output patch_v1.0.0_to_v1.1.0.bin
```

### Vantagens do Delta OTA

- 📉 **Tamanho reduzido**: Patches são ~95% menores que firmware completo
- ⚡ **Mais rápido**: Download e instalação mais rápidos
- 💰 **Economia**: Menos uso de dados e banda
- 🔄 **Eficiente**: Ideal para atualizações frequentes

### Documentação Completa

Ver **OTA_GUIDE.md** para guia completo de:
- Criação de patches delta
- Upload para backend
- Rollout gradual
- Troubleshooting
- Melhores práticas

## 📚 Documentação Adicional

- **CONFIG.md** - Detalhes de configuração
- **DEPLOYMENT_STATUS.md** - Status do deployment e checklist
- **OTA_GUIDE.md** - Guia completo de atualizações OTA
- **Documentação Técnica** - Ver `/docs/DOCUMENTACAO_TECNICA.md` na raiz do projeto

## 🔐 Segurança

⚠️ **IMPORTANTE**: As credenciais estão hardcoded no firmware para facilitar o desenvolvimento. Para produção:

1. **Use HTTPS** em vez de HTTP
2. **Implemente WiFi Manager** para configuração via web
3. **Use ESP32 NVS** com criptografia para armazenar credenciais
4. **Ative Secure Boot** e Flash Encryption
5. **Rotacione API Keys** regularmente
6. **Monitore dispositivos** para detectar anomalias

## 🛠️ Desenvolvimento

### Estrutura do Código

```
esp32-firmware/
├── platformio.ini          # Configuração do PlatformIO
├── src/
│   └── main.cpp           # Código principal do firmware
├── .env.example           # Template de variáveis de ambiente
├── CONFIG.md              # Documentação de configuração
├── DEPLOYMENT_STATUS.md   # Status do deployment
└── README.md              # Este arquivo
```

### Modificar Intervalos

Edite as constantes em `src/main.cpp`:

```cpp
const unsigned long TELEMETRY_INTERVAL = 5000;  // 5 segundos
const unsigned long HEARTBEAT_INTERVAL = 30000; // 30 segundos
const float USAGE_THRESHOLD = 1.0;              // m/s²
```

### Adicionar Novos Sensores

1. Adicione a biblioteca em `platformio.ini` → `lib_deps`
2. Inclua o header em `main.cpp`
3. Inicialize no `initSensors()`
4. Leia no `readSensors()`
5. Adicione ao payload JSON em `sendTelemetry()`

## 📊 Monitoramento

### Logs Serial

O firmware emite logs detalhados:

- 🔧 Inicialização de sensores
- 📡 Conexão WiFi
- 💓 Heartbeat
- 📊 Telemetria
- 👤 Detecção de uso
- 🚨 Alertas
- ❌ Erros

### Métricas Enviadas

**Telemetria (a cada 5s):**
- Aceleração (x, y, z)
- Giroscópio (x, y, z)
- Temperatura
- Pressão
- Nível de bateria
- Detecção de movimento
- Estado de uso (isWearing)

**Heartbeat (a cada 30s):**
- Status (online/offline)
- Nível de bateria
- Força do sinal WiFi (RSSI)
- Timestamp

## 🤝 Suporte

Para problemas ou dúvidas:

1. Verifique a seção de Troubleshooting
2. Consulte a documentação técnica
3. Verifique os logs do serial e do backend
4. Abra uma issue no repositório

## 📄 Licença

Copyright © 2024 OrthoTrack IoT Platform v3
