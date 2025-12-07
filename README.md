# OrthoTrack IoT Platform v3

Plataforma IoT completa para monitoramento de uso de coletes ortopédicos para pacientes com escoliose da AACD, utilizando sensores ESP32, análise de IA, dashboard web e aplicativo Android Edge Node.

## 🚀 Visão Geral

Esta é a terceira versão da plataforma OrtoTrack IoT, combinando:
- **Backend em GoLang** (baseado na estrutura do v1) 
- **Lógica de negócio** adaptada do v2 (PHP/Laravel)
- **Frontend Svelte** para dashboard administrativo
- **Aplicativo Android** como Node Edge para comunicação direta com ESP32

## 🏗️ Arquitetura

```
┌─────────────────┐    BLE     ┌─────────────────┐    HTTPS    ┌─────────────────┐
│  ESP32 Device   │ ←-------→  │ Android Edge    │ ←--------→  │  Backend API    │
│ (Colete AACD)   │            │ Node (Gateway)  │            │ (Go + PostgreSQL)│
└─────────────────┘            └─────────────────┘            └─────────────────┘
                                       ↑                              ↑
                                   WiFi/4G                         HTTPS
                                       ↓                              ↓
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Admin Dashboard (Svelte)                             │
│           ← Real-time monitoring, Analytics, AI Reports →                      │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 📁 Estrutura do Projeto

```
orthotrack-iot-v3/
├── backend/                    # API GoLang (baseado no v1)
│   ├── cmd/api/               # Ponto de entrada da aplicação
│   ├── internal/              # Código interno da aplicação
│   │   ├── models/            # Modelos de dados (baseados no v2)
│   │   ├── handlers/          # Handlers HTTP
│   │   ├── services/          # Lógica de negócio (adaptada do v2)
│   │   ├── database/          # Configuração e migrações
│   │   └── config/            # Configurações
│   ├── pkg/                   # Pacotes reutilizáveis
│   └── docs/                  # Documentação da API
│
├── frontend/                  # Dashboard Svelte (baseado no v1)
│   ├── src/
│   │   ├── routes/            # Páginas da aplicação
│   │   ├── lib/               # Componentes e serviços
│   │   └── stores/            # Stores Svelte
│   └── static/                # Arquivos estáticos
│
├── android-edge-node/         # Aplicativo Android (Node Edge)
│   ├── app/                   # Código principal do app
│   ├── esp32-ble/            # Módulo BLE para ESP32
│   ├── api-client/           # Cliente para API backend
│   └── offline-storage/      # Armazenamento offline
│
├── esp32-firmware/           # Firmware ESP32 (baseado no v1)
│   ├── src/                  # Código fonte C++
│   │   ├── sensors/          # Drivers de sensores
│   │   ├── ble/              # Comunicação Bluetooth
│   │   ├── ai/               # TinyML para detecção
│   │   └── power/            # Gerenciamento de energia
│   └── platformio.ini        # Configuração PlatformIO
│
├── docs/                     # Documentação geral
├── docker-compose.yml        # Orquestração de serviços
└── README.md                 # Este arquivo
```

## 🛠️ Tecnologias

### Backend (GoLang)
- **Framework**: Gin HTTP Framework
- **Banco de Dados**: PostgreSQL + Redis (cache)
- **ORM**: GORM
- **Autenticação**: JWT
- **AI**: OpenAI/DeepSeek API
- **MQTT**: Eclipse Paho (comunicação IoT)

### Frontend (Svelte)
- **Framework**: SvelteKit
- **UI**: Tailwind CSS + shadcn/ui
- **Charts**: Chart.js / D3.js
- **PWA**: Service Workers

### Android Edge Node
- **Linguagem**: Kotlin/Java
- **BLE**: Android Bluetooth LE API
- **HTTP Client**: OkHttp / Retrofit
- **Database**: Room (SQLite)
- **Background Tasks**: WorkManager

### ESP32 Firmware
- **Linguagem**: C++
- **Framework**: Arduino/ESP-IDF
- **Sensores**: MPU6050, DHT22, FSR, Hall Effect
- **AI**: TensorFlow Lite Micro
- **Comunicação**: BLE + WiFi

## 🚀 Quick Start

### Pré-requisitos
- Go 1.21+
- Node.js 18+
- PostgreSQL 14+
- Redis 6+
- Docker & Docker Compose
- Android Studio (para o app Android)
- PlatformIO (para firmware ESP32)

### 1. Backend (GoLang)
```bash
cd backend
go mod tidy
go run cmd/api/main.go
```

### 2. Frontend (Svelte)
```bash
cd frontend
npm install
npm run dev
```

### 3. Banco de Dados
```bash
docker-compose up -d postgres redis
```

### 4. Android Edge Node
```bash
# Abrir no Android Studio
# Compilar e instalar no dispositivo Android
```

### 5. ESP32 Firmware
```bash
cd esp32-firmware
pio run -t upload
```

## 📊 Funcionalidades Principais

### Backend GoLang
- ✅ API RESTful para gerenciamento de pacientes
- ✅ Processamento de telemetria em tempo real
- ✅ Sistema de alertas inteligentes
- ✅ Cálculo de compliance de uso
- ✅ Integração com IA para análises
- ✅ MQTT broker para comunicação IoT
- ✅ Sistema de cache com Redis
- ✅ Autenticação JWT

### Frontend Svelte
- ✅ Dashboard administrativo responsivo
- ✅ Monitoramento em tempo real
- ✅ Relatórios de compliance
- ✅ Gráficos e visualizações
- ✅ Gerenciamento de pacientes
- ✅ Configuração de dispositivos
- ✅ Exportação de relatórios

### Android Edge Node
- ✅ Comunicação BLE com ESP32
- ✅ Gateway local para dados IoT
- ✅ Armazenamento offline
- ✅ Sincronização automática
- ✅ Interface para configuração
- ✅ Notificações push
- ✅ Monitoramento de conectividade

### ESP32 Firmware
- ✅ Coleta de dados de múltiplos sensores
- ✅ Detecção de uso com TinyML
- ✅ Comunicação BLE otimizada
- ✅ Gerenciamento de energia
- ✅ OTA (Over-The-Air) updates
- ✅ Modo sleep inteligente

## 🔧 Configuração

### Variáveis de Ambiente (Backend)
```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=orthotrack_v3
DB_USER=orthotrack
DB_PASS=password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-secret-key

# AI Services
OPENAI_API_KEY=your-openai-key
DEEPSEEK_API_KEY=your-deepseek-key

# MQTT
MQTT_BROKER_URL=tcp://localhost:1883
```

### Configuração Android
```xml
<!-- android-edge-node/app/src/main/res/values/config.xml -->
<resources>
    <string name="api_base_url">https://your-api.com</string>
    <string name="mqtt_broker_url">tcp://your-mqtt.com:1883</string>
</resources>
```

## 📈 Modelos de Dados

### Principais Entidades (adaptadas do v2)
- **Patient**: Paciente com informações médicas
- **Ortese**: Dispositivo ESP32 associado ao paciente  
- **SensorReading**: Leituras dos sensores (acelerômetro, temperatura, etc.)
- **UsageSession**: Sessões de uso do aparelho
- **Alert**: Alertas do sistema (bateria baixa, baixo compliance, etc.)
- **DailyCompliance**: Relatórios diários de aderência
- **Institution**: Instituição médica
- **MedicalStaff**: Profissionais de saúde

## 🔒 Segurança

- Autenticação JWT para APIs
- Criptografia AES para dados sensíveis
- HTTPS obrigatório em produção
- Rate limiting nas APIs
- Validação rigorosa de inputs
- Logs de auditoria

## 📱 Aplicativo Android - Recursos

### Comunicação BLE
- Scan automático de dispositivos ESP32
- Conexão e pareamento seguro
- Troca de dados em tempo real
- Gerenciamento de múltiplas conexões

### Edge Computing
- Processamento local de dados
- Cache inteligente
- Sincronização offline-first
- Compressão de dados

### Interface do Usuário
- Dashboard em tempo real
- Configuração de dispositivos
- Monitoramento de status
- Logs de atividade

## 🚀 Deployment

### Docker Compose (Desenvolvimento)
```bash
docker-compose up -d
```

### Produção
```bash
# Backend
docker build -t orthotrack-api:v3 backend/
docker run -p 8080:8080 orthotrack-api:v3

# Frontend  
docker build -t orthotrack-frontend:v3 frontend/
docker run -p 3000:3000 orthotrack-frontend:v3
```

## 📋 Roadmap

- [x] Estrutura base do projeto
- [ ] Backend GoLang com modelos do v2
- [ ] Frontend Svelte adaptado
- [ ] App Android com comunicação BLE
- [ ] Firmware ESP32 otimizado
- [ ] Testes automatizados
- [ ] CI/CD pipeline
- [ ] Documentação completa

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma feature branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📄 Licença

Proprietary - OrtoTrack IoT Platform v3

---

**Desenvolvido para melhorar o tratamento ortodôntico através da IoT**# orthotrack-iot-v3
