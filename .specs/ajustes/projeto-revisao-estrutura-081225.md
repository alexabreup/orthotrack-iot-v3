# OrthoTrack IoT Platform - Guia Completo de Implementação

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Stack Tecnológica](#stack-tecnológica)
4. [Estrutura do Projeto](#estrutura-do-projeto)
5. [Instalação no VPS](#instalação-no-vps)
6. [Configuração do Backend Go](#configuração-do-backend-go)
7. [Configuração do Frontend Svelte](#configuração-do-frontend-svelte)
8. [Configuração do ESP32](#configuração-do-esp32)
9. [Deploy Automático](#deploy-automático)
10. [Monitoramento e Manutenção](#monitoramento-e-manutenção)

---

## 🎯 Visão Geral

**OrthoTrack IoT Platform** é um sistema completo de monitoramento de compliance de órteses ortopédicas para pacientes com escoliose, desenvolvido em parceria com a AACD como projeto de conclusão do SENAI.

### Objetivos

- Monitorar em tempo real o uso de órteses ortopédicas
- Calcular compliance (adesão ao tratamento)
- Alertar pacientes e equipe médica sobre não conformidades
- Fornecer dashboards e relatórios para análise

### Decisões Técnicas

**Por que Go + Svelte + MQTT?**

- ✅ **Performance**: 10x mais rápido que Laravel/Node.js
- ✅ **Concorrência**: Goroutines nativas para múltiplos dispositivos
- ✅ **Memória**: 90% menos consumo (20MB vs 200MB)
- ✅ **Deploy**: Single binary, sem dependências complexas
- ✅ **Escalabilidade**: Suporta centenas de dispositivos simultâneos

---

## 🏗️ Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    ESP32 Devices (Órteses)                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ ESP32_01 │  │ ESP32_02 │  │ ESP32_03 │  │ ESP32_N  │   │
│  │MPU6050   │  │MPU6050   │  │MPU6050   │  │MPU6050   │   │
│  │DHT22     │  │DHT22     │  │DHT22     │  │DHT22     │   │
│  │Hall      │  │Hall      │  │Hall      │  │Hall      │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │ WiFi        │ WiFi        │ WiFi        │ WiFi     │
└───────┼─────────────┼─────────────┼─────────────┼──────────┘
        │             │             │             │
        └─────────────┴─────────────┴─────────────┘
                      │ MQTT (1883)
                      ▼
        ┌─────────────────────────┐
        │   Mosquitto MQTT Broker │
        │      (Docker)           │
        └────────────┬────────────┘
                     │
                     ▼
        ┌─────────────────────────┐
        │   Go Backend Server     │
        │  ┌──────────────────┐   │
        │  │ MQTT Subscriber  │   │
        │  │ (goroutines)     │   │
        │  ├──────────────────┤   │
        │  │ REST API         │   │
        │  │ (Fiber)          │   │
        │  ├──────────────────┤   │
        │  │ WebSocket Server │   │
        │  │ (real-time)      │   │
        │  ├──────────────────┤   │
        │  │ Business Logic   │   │
        │  │ (compliance)     │   │
        │  └──────────────────┘   │
        └────────────┬────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────┐        ┌──────────────────┐
│ PostgreSQL + │        │  Svelte Frontend │
│ TimescaleDB  │◄───────│   (SvelteKit)    │
│              │  REST  │                  │
│ Time-series  │        │ - Dashboard      │
│ sensor data  │        │ - Real-time      │
└──────────────┘        │ - Charts         │
                        │ - Alerts         │
                        └──────────────────┘
```

### Fluxo de Dados

1. **ESP32** coleta dados dos sensores (MPU6050, DHT22, Hall, Pressure)
2. **MQTT** publica dados no tópico `orthotrack/devices/{id}/data`
3. **Mosquitto** roteia mensagens para subscribers
4. **Go Backend** processa via goroutine dedicada
5. **PostgreSQL** armazena dados (TimescaleDB para séries temporais)
6. **WebSocket** notifica frontend em tempo real
7. **Svelte** atualiza dashboard instantaneamente

---

## 🛠️ Stack Tecnológica

### Backend (Go)

```go
// Core
- Go 1.21+
- Fiber v2 (framework web ultra-rápido)
- paho.mqtt.golang (cliente MQTT)

// Database
- pgx v5 (driver PostgreSQL performático)
- GORM v2 (ORM para produtividade)
- TimescaleDB extension (séries temporais)

// Real-time
- gorilla/websocket (WebSocket server)

// Utilities
- godotenv (variáveis ambiente)
- zerolog (logging estruturado)
- validator/v10 (validação de dados)
- jwt-go v5 (autenticação JWT)
```

### Frontend (Svelte)

```javascript
// Core
- SvelteKit 2.0 (SSR + SPA)
- TypeScript

// Visualização
- Chart.js 4.0 (gráficos)
- Tailwind CSS 3.0 (styling)

// Estado & Real-time
- Svelte Stores (state management)
- Native WebSocket API
```

### Infraestrutura

```yaml
- Docker 24+ & Docker Compose v2
- Mosquitto MQTT Broker 2.0
- PostgreSQL 16 + TimescaleDB 2.13
- Nginx (reverse proxy + SSL)
- Ubuntu 22.04 LTS (VPS)
```

### Hardware (ESP32)

```cpp
- ESP32-WROOM-32
- MPU6050 (acelerômetro/giroscópio I2C)
- DHT22 (temperatura/umidade)
- FSR (Force Sensitive Resistor)
- Sensor Hall (magnético)
```

---

## 📁 Estrutura do Projeto

```
orthotrack-iot-platform/
├── backend/                    # Go API Server
│   ├── cmd/
│   │   └── api/
│   │       └── main.go        # Entry point
│   ├── internal/
│   │   ├── config/            # Configurações
│   │   │   └── config.go
│   │   ├── database/          # DB connection
│   │   │   ├── connection.go
│   │   │   └── migrations.go
│   │   ├── handlers/          # HTTP handlers
│   │   │   ├── device.go
│   │   │   ├── patient.go
│   │   │   └── alert.go
│   │   ├── models/            # Data models
│   │   │   ├── device.go
│   │   │   ├── patient.go
│   │   │   ├── reading.go
│   │   │   └── alert.go
│   │   ├── mqtt/              # MQTT client
│   │   │   └── client.go
│   │   ├── services/          # Business logic
│   │   │   ├── device.go
│   │   │   ├── patient.go
│   │   │   ├── reading.go
│   │   │   └── alert.go
│   │   └── websocket/         # WebSocket hub
│   │       └── hub.go
│   ├── migrations/            # SQL migrations
│   │   ├── 001_create_devices.up.sql
│   │   ├── 002_create_patients.up.sql
│   │   └── 003_create_readings.up.sql
│   ├── go.mod
│   ├── go.sum
│   ├── Dockerfile
│   └── .env.example
│
├── frontend/                   # Svelte Dashboard
│   ├── src/
│   │   ├── lib/
│   │   │   ├── api/           # API client
│   │   │   │   └── client.ts
│   │   │   ├── components/    # Svelte components
│   │   │   │   ├── DeviceCard.svelte
│   │   │   │   ├── AlertBanner.svelte
│   │   │   │   └── Chart.svelte
│   │   │   └── stores/        # State management
│   │   │       ├── devices.ts
│   │   │       └── websocket.ts
│   │   ├── routes/
│   │   │   ├── +page.svelte   # Home/Dashboard
│   │   │   ├── +layout.svelte
│   │   │   ├── devices/       # Dispositivos
│   │   │   │   ├── +page.svelte
│   │   │   │   └── [id]/+page.svelte
│   │   │   ├── patients/      # Pacientes
│   │   │   │   ├── +page.svelte
│   │   │   │   └── [id]/+page.svelte
│   │   │   └── reports/       # Relatórios
│   │   │       └── +page.svelte
│   │   └── app.html
│   ├── static/
│   ├── svelte.config.js
│   ├── vite.config.js
│   ├── tailwind.config.js
│   ├── package.json
│   ├── Dockerfile
│   └── .env.example
│
├── esp32/                      # Código ESP32
│   ├── orthotrack-device/
│   │   ├── orthotrack-device.ino
│   │   ├── config.h           # WiFi & MQTT config
│   │   └── sensors.h          # Sensor libraries
│   └── README.md
│
├── infrastructure/             # Deploy configs
│   ├── docker-compose.yml     # Produção
│   ├── docker-compose.dev.yml # Desenvolvimento
│   ├── nginx/
│   │   └── default.conf       # Reverse proxy
│   ├── mosquitto/
│   │   └── mosquitto.conf     # MQTT broker config
│   └── postgresql/
│       └── init.sql           # Schema inicial
│
├── scripts/                    # Automação
│   ├── install.sh             # Setup completo VPS
│   ├── deploy.sh              # Deploy atualização
│   ├── backup.sh              # Backup DB
│   └── monitor.sh             # Health check
│
├── docs/                       # Documentação
│   ├── API.md                 # API Reference
│   ├── DEPLOYMENT.md          # Guia de Deploy
│   └── HARDWARE.md            # Especificações ESP32
│
├── .env.production            # Variáveis produção
├── .gitignore
└── README.md
```

---

## 🚀 Instalação no VPS

### Pré-requisitos

- VPS Ubuntu 22.04 LTS (Hostinger)
- 2GB RAM mínimo (4GB recomendado)
- 20GB disco
- Acesso root via SSH

### Script de Instalação Automática

**Arquivo: `scripts/install.sh`**

```bash
#!/bin/bash
set -e

echo "=============================================="
echo "   OrthoTrack IoT Platform - Auto Installer"
echo "=============================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, execute como root (sudo)${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/8] Atualizando sistema...${NC}"
apt-get update
apt-get upgrade -y

echo -e "${YELLOW}[2/8] Instalando dependências...${NC}"
apt-get install -y \
    curl \
    wget \
    git \
    ufw \
    fail2ban \
    certbot \
    python3-certbot-nginx

echo -e "${YELLOW}[3/8] Instalando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}✓ Docker instalado${NC}"
else
    echo -e "${GREEN}✓ Docker já está instalado${NC}"
fi

echo -e "${YELLOW}[4/8] Instalando Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose instalado${NC}"
else
    echo -e "${GREEN}✓ Docker Compose já está instalado${NC}"
fi

echo -e "${YELLOW}[5/8] Configurando Firewall...${NC}"
ufw --force enable
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw allow 1883/tcp    # MQTT
ufw allow 8883/tcp    # MQTT SSL
echo -e "${GREEN}✓ Firewall configurado${NC}"

echo -e "${YELLOW}[6/8] Criando diretório do projeto...${NC}"
PROJECT_DIR="/opt/orthotrack"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

echo -e "${YELLOW}[7/8] Criando estrutura de pastas...${NC}"
mkdir -p backend frontend infrastructure/{nginx,mosquitto,postgresql} scripts

echo -e "${YELLOW}[8/8] Criando arquivo .env...${NC}"
cat > .env.production << 'EOF'
# Database
POSTGRES_USER=orthotrack
POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD
POSTGRES_DB=orthotrack_db
DATABASE_URL=postgres://orthotrack:CHANGE_ME_STRONG_PASSWORD@postgres:5432/orthotrack_db

# Backend API
API_PORT=8080
JWT_SECRET=CHANGE_ME_RANDOM_STRING_64_CHARS
API_URL=http://localhost:8080

# MQTT Broker
MQTT_HOST=mosquitto
MQTT_PORT=1883
MQTT_USER=orthotrack
MQTT_PASSWORD=CHANGE_ME_MQTT_PASSWORD

# Frontend
PUBLIC_API_URL=https://seu-dominio.com/api
PUBLIC_WS_URL=wss://seu-dominio.com/ws

# Domain (para SSL)
DOMAIN=seu-dominio.com
EMAIL=seu-email@exemplo.com
EOF

echo ""
echo -e "${GREEN}=============================================="
echo -e "  Instalação Base Concluída!"
echo -e "==============================================${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Edite .env.production com suas credenciais:"
echo "   nano $PROJECT_DIR/.env.production"
echo ""
echo "2. Adicione os arquivos do projeto em:"
echo "   - $PROJECT_DIR/backend/"
echo "   - $PROJECT_DIR/frontend/"
echo "   - $PROJECT_DIR/infrastructure/"
echo ""
echo "3. Execute o deploy:"
echo "   bash $PROJECT_DIR/scripts/deploy.sh"
echo ""
echo -e "${GREEN}Instalação finalizada com sucesso!${NC}"
```

### Executar Instalação

```bash
# 1. Conectar ao VPS
ssh root@SEU_IP_VPS

# 2. Baixar script
wget https://raw.githubusercontent.com/seu-usuario/orthotrack/main/scripts/install.sh

# 3. Dar permissão e executar
chmod +x install.sh
sudo bash install.sh

# 4. Editar configurações
nano /opt/orthotrack/.env.production
```

---

## ⚙️ Configuração do Backend Go

### go.mod

```go
module orthotrack

go 1.21

require (
	github.com/gofiber/fiber/v2 v2.52.0
	github.com/gofiber/websocket/v2 v2.2.1
	github.com/eclipse/paho.mqtt.golang v1.4.3
	github.com/lib/pq v1.10.9
	github.com/jmoiron/sqlx v1.3.5
	gorm.io/gorm v1.25.5
	gorm.io/driver/postgres v1.5.4
	github.com/golang-jwt/jwt/v5 v5.2.0
	github.com/joho/godotenv v1.5.1
	github.com/rs/zerolog v1.31.0
	github.com/go-playground/validator/v10 v10.16.0
)
```

### internal/config/config.go

```go
package config

import (
	"os"
	"strconv"
)

type Config struct {
	DatabaseURL string
	APIPort     string
	JWTSecret   string
	MQTT        MQTTConfig
}

type MQTTConfig struct {
	Host     string
	Port     int
	User     string
	Password string
}

func Load() *Config {
	mqttPort, _ := strconv.Atoi(getEnv("MQTT_PORT", "1883"))

	return &Config{
		DatabaseURL: getEnv("DATABASE_URL", ""),
		APIPort:     getEnv("API_PORT", "8080"),
		JWTSecret:   getEnv("JWT_SECRET", ""),
		MQTT: MQTTConfig{
			Host:     getEnv("MQTT_HOST", "localhost"),
			Port:     mqttPort,
			User:     getEnv("MQTT_USER", ""),
			Password: getEnv("MQTT_PASSWORD", ""),
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
```

### internal/models/device.go

```go
package models

import "time"

type Device struct {
	ID           int64     `json:"id" db:"id"`
	DeviceID     string    `json:"device_id" db:"device_id"`
	PatientID    *int64    `json:"patient_id,omitempty" db:"patient_id"`
	MACAddress   string    `json:"mac_address" db:"mac_address"`
	FirmwareVer  string    `json:"firmware_version" db:"firmware_version"`
	BatteryLevel int       `json:"battery_level" db:"battery_level"`
	Status       string    `json:"status" db:"status"` // online, offline, maintenance
	LastSeen     time.Time `json:"last_seen" db:"last_seen"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

type SensorReading struct {
	ID          int64     `json:"id" db:"id"`
	DeviceID    int64     `json:"device_id" db:"device_id"`
	Timestamp   time.Time `json:"timestamp" db:"timestamp"`
	AccelX      float64   `json:"accel_x" db:"accel_x"`
	AccelY      float64   `json:"accel_y" db:"accel_y"`
	AccelZ      float64   `json:"accel_z" db:"accel_z"`
	GyroX       float64   `json:"gyro_x" db:"gyro_x"`
	GyroY       float64   `json:"gyro_y" db:"gyro_y"`
	GyroZ       float64   `json:"gyro_z" db:"gyro_z"`
	Temperature float64   `json:"temperature" db:"temperature"`
	Humidity    float64   `json:"humidity" db:"humidity"`
	Pressure    int       `json:"pressure_value" db:"pressure_value"`
	BraceClosed bool      `json:"brace_closed" db:"brace_closed"`
	IsWearing   bool      `json:"is_wearing" db:"is_wearing"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}
```

### Docker Compose

**Arquivo: `infrastructure/docker-compose.yml`**

```yaml
version: '3.8'

services:
  # PostgreSQL + TimescaleDB
  postgres:
    image: timescale/timescaledb:latest-pg16
    container_name: orthotrack-db
    restart: always
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgresql/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Mosquitto MQTT Broker
  mosquitto:
    image: eclipse-mosquitto:2
    container_name: orthotrack-mqtt
    restart: always
    volumes:
      - ./mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf
      - mosquitto_data:/mosquitto/data
      - mosquitto_logs:/mosquitto/log
    ports:
      - "1883:1883"
      - "9001:9001"
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "mosquitto_sub", "-t", "$$SYS/#", "-C", "1", "-i", "healthcheck", "-W", "3"]
      interval: 10s
      timeout: 5s
      retries: 3

  # Backend Go API
  backend:
    build:
      context: ../backend
      dockerfile: Dockerfile
    container_name: orthotrack-api
    restart: always
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - MQTT_HOST=${MQTT_HOST}
      - MQTT_PORT=${MQTT_PORT}
      - MQTT_USER=${MQTT_USER}
      - MQTT_PASSWORD=${MQTT_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - API_PORT=${API_PORT}
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      mosquitto:
        condition: service_healthy
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 15s
      timeout: 5s
      retries: 3

  # Frontend Svelte
  frontend:
    build:
      context: ../frontend
      dockerfile: Dockerfile
    container_name: orthotrack-web
    restart: always
    environment:
      - PUBLIC_API_URL=${PUBLIC_API_URL}
      - PUBLIC_WS_URL=${PUBLIC_WS_URL}
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - orthotrack-network

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: orthotrack-nginx
    restart: always
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
      - certbot_www:/var/www/certbot
      - certbot_conf:/etc/letsencrypt
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - backend
      - frontend
    networks:
      - orthotrack-network

networks:
  orthotrack-network:
    driver: bridge

volumes:
  postgres_data:
  mosquitto_data:
  mosquitto_logs:
  certbot_www:
  certbot_conf:
```

---

## 🎨 Configuração do Frontend Svelte

### package.json

```json
{
  "name": "orthotrack-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "@sveltejs/adapter-node": "^2.0.0",
    "@sveltejs/kit": "^2.0.0",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32",
    "svelte": "^4.2.8",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.3.3",
    "vite": "^5.0.10"
  },
  "dependencies": {
    "chart.js": "^4.4.1"
  }
}
```

### Dockerfile Frontend

```dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/build ./build
COPY --from=builder /app/package*.json ./

RUN npm ci --production

EXPOSE 3000

CMD ["node", "build"]
```

---

## 🔌 Configuração do ESP32

### Bibliotecas Necessárias

```cpp
// Arduino IDE > Library Manager > Instalar:
- PubSubClient by Nick O'Leary
- MPU6050 by Electronic Cats
- DHT sensor library by Adafruit
- ArduinoJson by Benoit Blanchon
```

### config.h

```cpp
#ifndef CONFIG_H
#define CONFIG_H

// WiFi Credentials
#define WIFI_SSID "SEU_WIFI"
#define WIFI_PASSWORD "SUA_SENHA_WIFI"

// MQTT Broker
#define MQTT_SERVER "IP_DO_SEU_VPS"  // Ex: "192.168.1.100"
#define MQTT_PORT 1883
#define MQTT_USER "orthotrack"
#define MQTT_PASSWORD "sua_senha_mqtt"

// Device Info
#define DEVICE_ID "ORTHO_ESP32_001"
#define PATIENT_ID "PAT_001"

// Sensor Pins
#define DHT_PIN 4
#define PRESSURE_PIN 34
#define HALL_PIN 35

// Intervals
#define SEND_INTERVAL 5000  // 5 segundos
#define RECONNECT_INTERVAL 5000

#endif
```

---

## 🚀 Deploy Automático

### scripts/deploy.sh

```bash
#!/bin/bash
set -e

echo "=============================================="
echo "   OrthoTrack IoT - Deploy Automático"
echo "=============================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/opt/orthotrack"
cd $PROJECT_DIR

echo -e "${YELLOW}[1/7] Verificando arquivos...${NC}"
if [ ! -f ".env.production" ]; then
    echo -e "${RED}Erro: .env.production não encontrado${NC}"
    exit 1
fi

echo -e "${YELLOW}[2/7] Parando containers antigos...${NC}"
cd infrastructure
docker-compose --env-file ../.env.production down

echo -e "${YELLOW}[3/7] Removendo imagens antigas...${NC}"
docker system prune -f

echo -e "${YELLOW}[4/7] Buildando novas imagens...${NC}"
docker-compose --env-file ../.env.production build --no-cache

echo -e "${YELLOW}[5/7] Iniciando containers...${NC}"
docker-compose --env-file ../.env.production up -d

echo -e "${YELLOW}[6/7] Aguardando serviços...${NC}"
sleep 20

echo -e "${YELLOW}[7/7] Verificando status...${NC}"
docker-compose --env-file ../.env.production ps

echo ""
echo -e "${GREEN}Deploy Concluído!${NC}"
echo ""
echo "Serviços:"
echo "  Frontend: http://seu-ip:3000"
echo "  Backend: http://seu-ip:8080"
echo "  MQTT: mqtt://seu-ip:1883"
```

---

## 📊 Monitoramento e Manutenção

### Health Checks

```bash
# Verificar status dos containers
docker-compose -f infrastructure/docker-compose.yml ps

# Ver logs em tempo real
docker-compose -f infrastructure/docker-compose.yml logs -f backend

# Testar API
curl http://localhost:8080/health

# Testar MQTT
mosquitto_sub -h localhost -t "orthotrack/#" -v
```

### Backup Automático

**scripts/backup.sh**

```bash
#!/bin/bash
BACKUP_DIR="/backup/orthotrack"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker exec orthotrack-db pg_dump -U orthotrack orthotrack_db > "$BACKUP_DIR/db_$DATE.sql