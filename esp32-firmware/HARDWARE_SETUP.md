# Guia de Conexão de Hardware - ESP32-WROOM-32

## 📋 Lista de Componentes

### Obrigatórios
- [x] 1x ESP32-WROOM-32 Development Board
- [x] 1x MPU6050 (Acelerômetro + Giroscópio)
- [x] 1x BMP280 (Temperatura + Pressão)
- [x] 1x TTP223 (Sensor de Toque Capacitivo) - **NOVO**
- [x] 1x Cabo USB (com suporte a dados)
- [x] Breadboard
- [x] Jumper wires (macho-macho e macho-fêmea)

### Opcionais
- [ ] Bateria Li-ion 3.7V (1000-2000mAh)
- [ ] Módulo carregador TP4056
- [ ] Divisor de tensão (2x resistores 10kΩ)
- [ ] LED indicador (opcional)
- [ ] Resistor 220Ω (para LED)

## 🔌 Diagrama de Conexão

```
┌─────────────────────────────────────────────────────────────┐
│                    ESP32-WROOM-32                            │
│                                                               │
│  3.3V ────┬────────────────────────────────────┐            │
│           │                                     │            │
│  GND  ────┼────┬────────────────────────────┐  │            │
│           │    │                             │  │            │
│  GPIO21 ──┼────┼─── SDA (I2C) ──────────────┼──┼────┐      │
│  (SDA)    │    │                             │  │    │      │
│           │    │                             │  │    │      │
│  GPIO22 ──┼────┼─── SCL (I2C) ──────────────┼──┼────┼──┐   │
│  (SCL)    │    │                             │  │    │  │   │
│           │    │                             │  │    │  │   │
│  GPIO35 ──┼────┼─── Battery ADC (opcional)  │  │    │  │   │
│  (ADC)    │    │                             │  │    │  │   │
│           │    │                             │  │    │  │   │
│  GPIO4  ──┼────┼─── Touch Sensor (TTP223)   │  │    │  │   │
│           │    │                             │  │    │  │   │
└───────────┼────┼─────────────────────────────┼──┼────┼──┼───┘
            │    │                             │  │    │  │
            │    │                             │  │    │  │
      ┌─────▼────▼─────┐             ┌────────▼──▼────▼──▼───┐
      │    MPU6050      │             │      BMP280           │
      │                 │             │                       │
      │  VCC ← 3.3V     │             │  VCC ← 3.3V          │
      │  GND ← GND      │             │  GND ← GND           │
      │  SDA ← GPIO21   │             │  SDA ← GPIO21        │
      │  SCL ← GPIO22   │             │  SCL ← GPIO22        │
      │  (AD0 → GND)    │             │  (SDO → GND)         │
      └─────────────────┘             └──────────────────────┘
```

## 📐 Pinout Detalhado

### ESP32-WROOM-32

| Pino ESP32 | Função | Conectar a |
|------------|--------|------------|
| 3.3V | Alimentação | VCC do MPU6050 e BMP280 |
| GND | Terra | GND do MPU6050 e BMP280 |
| GPIO21 | SDA (I2C) | SDA do MPU6050 e BMP280 |
| GPIO22 | SCL (I2C) | SCL do MPU6050 e BMP280 |
| GPIO35 | ADC (Bateria) | Divisor de tensão da bateria |
| GPIO4 | Digital Input | Sensor de toque TTP223 |
| EN | Reset | Botão de reset (opcional) |

### MPU6050

| Pino MPU6050 | Conectar a | Notas |
|--------------|------------|-------|
| VCC | 3.3V ESP32 | **NÃO use 5V!** |
| GND | GND ESP32 | |
| SDA | GPIO21 ESP32 | Barramento I2C |
| SCL | GPIO22 ESP32 | Barramento I2C |
| AD0 | GND | Define endereço I2C 0x68 |
| INT | Não conectar | Interrupção (não usado) |

### BMP280

| Pino BMP280 | Conectar a | Notas |
|-------------|------------|-------|
| VCC | 3.3V ESP32 | Pode usar 3.3V ou 5V |
| GND | GND ESP32 | |
| SDA | GPIO21 ESP32 | Barramento I2C (mesmo do MPU6050) |
| SCL | GPIO22 ESP32 | Barramento I2C (mesmo do MPU6050) |
| SDO | GND | Define endereço I2C 0x76 |
| CSB | 3.3V | Modo I2C (não SPI) |

### TTP223 (Sensor de Toque)

| Pino TTP223 | Conectar a | Notas |
|-------------|------------|-------|
| VCC | 3.3V ESP32 | Alimentação 3.3V |
| GND | GND ESP32 | Terra comum |
| SIG/OUT | GPIO4 ESP32 | Saída digital (HIGH quando tocado) |

> **📖 Guia Detalhado**: Veja [TTP223_SETUP.md](TTP223_SETUP.md) para instruções completas de instalação e configuração do sensor de toque.

## 🔋 Conexão de Bateria (Opcional)

### Circuito de Monitoramento

```
Bateria Li-ion (3.7V)
    │
    ├─── (+) ──► TP4056 ──► ESP32 VIN/5V
    │
    └─── Divisor de Tensão ──► GPIO35 (ADC)
              │
              ├─── R1 (10kΩ) ──► Bateria+
              │
              ├─── R2 (10kΩ) ──► GND
              │
              └─── Ponto médio ──► GPIO35
```

### Cálculo do Divisor de Tensão

- Bateria: 3.0V (vazia) a 4.2V (cheia)
- ADC ESP32: 0-3.3V (máximo)
- Divisor 1:2 (R1=R2=10kΩ)
- Tensão no ADC = Vbat / 2
- 4.2V / 2 = 2.1V (dentro do range do ADC)

## 🛠️ Passo a Passo da Montagem

### 1. Preparação

```bash
# Verificar componentes
✓ ESP32-WROOM-32
✓ MPU6050
✓ BMP280
✓ TTP223
✓ Breadboard
✓ Jumpers
✓ Cabo USB
```

### 2. Conexões de Alimentação

1. **Conectar 3.3V**:
   - ESP32 3.3V → Trilha positiva da breadboard
   - Trilha positiva → VCC do MPU6050
   - Trilha positiva → VCC do BMP280

2. **Conectar GND**:
   - ESP32 GND → Trilha negativa da breadboard
   - Trilha negativa → GND do MPU6050
   - Trilha negativa → GND do BMP280

### 3. Conexões I2C

1. **SDA (Dados)**:
   - ESP32 GPIO21 → SDA do MPU6050
   - SDA do MPU6050 → SDA do BMP280
   - (Todos no mesmo barramento)

2. **SCL (Clock)**:
   - ESP32 GPIO22 → SCL do MPU6050
   - SCL do MPU6050 → SCL do BMP280
   - (Todos no mesmo barramento)

### 4. Configuração de Endereços I2C

1. **MPU6050**:
   - Conectar pino AD0 ao GND
   - Endereço I2C: 0x68

2. **BMP280**:
   - Conectar pino SDO ao GND
   - Conectar pino CSB ao 3.3V (modo I2C)
   - Endereço I2C: 0x76

### 5. Verificação

```bash
# Conectar ESP32 ao computador via USB
# Verificar porta COM
pio device list

# Fazer upload de firmware de teste I2C
# (opcional, para verificar conexões)
```

## 🔍 Verificação de Conexões

### Checklist Visual

- [ ] Todos os fios estão bem conectados
- [ ] Não há curtos-circuitos
- [ ] VCC está em 3.3V (não 5V para MPU6050)
- [ ] GND comum para todos os componentes
- [ ] SDA e SCL conectados corretamente
- [ ] AD0 do MPU6050 está em GND
- [ ] SDO do BMP280 está em GND
- [ ] CSB do BMP280 está em 3.3V

### Teste com Multímetro

1. **Tensão de Alimentação**:
   ```
   Medir entre 3.3V e GND: deve ser ~3.3V
   Medir VCC do MPU6050: deve ser ~3.3V
   Medir VCC do BMP280: deve ser ~3.3V
   ```

2. **Continuidade**:
   ```
   Verificar continuidade de GND
   Verificar continuidade de SDA
   Verificar continuidade de SCL
   ```

3. **Curto-Circuito**:
   ```
   Medir entre 3.3V e GND: deve ser >1kΩ
   Não deve haver curto entre pinos adjacentes
   ```

## 📸 Fotos de Referência

### Vista Geral
```
[Breadboard com ESP32, MPU6050 e BMP280 conectados]
```

### Detalhe das Conexões I2C
```
[Close-up dos pinos SDA e SCL]
```

### Conexão USB
```
[ESP32 conectado ao computador]
```

## ⚠️ Avisos Importantes

### ⚡ Alimentação

- **NUNCA** conecte 5V ao MPU6050 (apenas 3.3V)
- BMP280 aceita 3.3V ou 5V, mas use 3.3V por consistência
- Verifique polaridade da bateria antes de conectar

### 🔌 I2C

- Máximo de 400kHz para I2C (configurado no código)
- Resistores pull-up geralmente já estão nos módulos
- Se houver problemas, adicione pull-ups externos (4.7kΩ)

### 🔥 Proteção

- Não inverta polaridade da bateria
- Use módulo TP4056 com proteção de sobrecarga
- Não curto-circuite os pinos
- Desconecte bateria ao fazer upload via USB

### 🌡️ Temperatura

- ESP32 pode aquecer durante operação normal
- MPU6050 e BMP280 são sensíveis a temperatura
- Mantenha ventilação adequada

## 🧪 Teste de Funcionamento

### 1. Teste Básico

```bash
# Upload do firmware
cd esp32-firmware
pio run --target upload

# Abrir monitor serial
pio device monitor
```

**Saída esperada:**
```
=== OrthoTrack ESP32 Firmware v3.0 ===
Inicializando MPU6050... ✅ OK
Inicializando BMP280... ✅ OK
Inicializando TTP223... ✅ OK
Conectando WiFi........... ✅ Conectado!
IP: 192.168.1.100
✅ Sistema inicializado com sucesso!
```

### 2. Teste de Sensores

**Mover o ESP32** e observar:
```
📊 Aceleração: X=0.5 Y=-0.2 Z=9.8 m/s²
🌡️  Temperatura: 25.5°C
📈 Pressão: 1013.25 hPa
👆 Toque: Não detectado
```

**Tocar o sensor TTP223** e observar:
```
👆 Toque: ✓ DETECTADO
👤 Estado de uso: EM USO
```

### 3. Teste de Conectividade

**Verificar envio de dados:**
```
💓 Heartbeat enviado
📡 Telemetria enviada
```

## 🐛 Troubleshooting

### MPU6050 não detectado

**Problema**: `❌ Falha ao inicializar MPU6050`

**Soluções**:
1. Verificar conexões SDA e SCL
2. Verificar alimentação 3.3V
3. Verificar AD0 está em GND
4. Testar com I2C scanner
5. Trocar módulo MPU6050

### BMP280 não detectado

**Problema**: `❌ Falha ao inicializar BMP280`

**Soluções**:
1. Verificar conexões I2C
2. Verificar SDO está em GND (endereço 0x76)
3. Verificar CSB está em 3.3V (modo I2C)
4. Tentar endereço 0x77 (SDO em VCC)
5. Trocar módulo BMP280

### WiFi não conecta

**Problema**: `❌ Falha na conexão WiFi`

**Soluções**:
1. Verificar SSID e senha
2. Verificar rede é 2.4GHz (não 5GHz)
3. Verificar alcance do sinal
4. Reiniciar roteador
5. Verificar firewall

### ESP32 não é reconhecido

**Problema**: Porta COM não aparece

**Soluções**:
1. Instalar drivers CP210x ou CH340
2. Trocar cabo USB (usar cabo de dados)
3. Trocar porta USB do computador
4. Verificar se ESP32 está ligado
5. Pressionar botão BOOT durante conexão

## 📚 Recursos Adicionais

### Datasheets

- [ESP32-WROOM-32](https://www.espressif.com/sites/default/files/documentation/esp32-wroom-32_datasheet_en.pdf)
- [MPU6050](https://invensense.tdk.com/wp-content/uploads/2015/02/MPU-6000-Datasheet1.pdf)
- [BMP280](https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmp280-ds001.pdf)

### Tutoriais

- [ESP32 I2C Tutorial](https://randomnerdtutorials.com/esp32-i2c-communication-arduino-ide/)
- [MPU6050 with ESP32](https://randomnerdtutorials.com/esp32-mpu-6050-accelerometer-gyroscope-arduino/)
- [BMP280 with ESP32](https://randomnerdtutorials.com/esp32-bmp280-arduino/)

### Ferramentas

- [I2C Scanner](https://playground.arduino.cc/Main/I2cScanner/)
- [ESP32 Pinout Reference](https://randomnerdtutorials.com/esp32-pinout-reference-gpios/)

---

**Próximo passo**: Após verificar todas as conexões, prosseguir com o upload do firmware (Tarefa 5)
