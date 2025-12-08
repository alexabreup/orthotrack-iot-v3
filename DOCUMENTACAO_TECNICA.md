# Documentação Técnica - OrthoTrack IoT Platform v3

## 📋 Índice

1. [Visão Geral do Sistema](#1-visão-geral-do-sistema)
2. [Arquitetura do Sistema](#2-arquitetura-do-sistema)
3. [Componentes Principais](#3-componentes-principais)
4. [Fluxos de Dados](#4-fluxos-de-dados)
5. [Modelos de Dados](#5-modelos-de-dados)
6. [APIs e Endpoints](#6-apis-e-endpoints)
7. [Processamento de Dados](#7-processamento-de-dados)
8. [Sistema de Alertas](#8-sistema-de-alertas)
9. [Autenticação e Segurança](#9-autenticação-e-segurança)
10. [Integrações](#10-integrações)
11. [Deploy e Operação](#11-deploy-e-operação)

---

## 1. Visão Geral do Sistema

### 1.1 Objetivo

O **OrthoTrack IoT Platform v3** é uma plataforma completa de monitoramento de uso de coletes ortopédicos para pacientes com escoliose. O sistema coleta dados em tempo real de sensores embarcados em dispositivos ESP32, processa informações através de Edge Computing e Cloud Computing, e fornece insights através de dashboards web e aplicativos móveis.

### 1.2 Casos de Uso Principais

- **Monitoramento de Compliance**: Acompanhamento do tempo de uso diário do colete ortopédico
- **Análise de Postura**: Detecção de postura correta/incorreta durante o uso
- **Alertas Inteligentes**: Notificações automáticas para bateria baixa, baixa compliance, problemas técnicos
- **Relatórios Médicos**: Geração de relatórios de aderência ao tratamento para profissionais de saúde
- **Análise com IA**: Insights gerados por IA sobre padrões de uso e recomendações

### 1.3 Stack Tecnológico

#### Backend
- **Linguagem**: Go 1.21+
- **Framework HTTP**: Gin
- **Banco de Dados**: PostgreSQL 14+
- **Cache**: Redis 6+
- **ORM**: GORM
- **Autenticação**: JWT
- **Message Queue**: MQTT (Eclipse Paho)
- **Documentação**: Swagger/OpenAPI

#### Frontend
- **Framework**: SvelteKit
- **UI**: Tailwind CSS + shadcn/ui
- **Gráficos**: Chart.js
- **PWA**: Service Workers

#### Firmware
- **Plataforma**: ESP32
- **Linguagem**: C++ (Arduino/ESP-IDF)
- **Sensores**: MPU6050, DHT22, FSR, Hall Effect
- **AI**: TensorFlow Lite Micro

---

## 2. Arquitetura do Sistema

### 2.1 Arquitetura de Alto Nível

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLOUD LAYER                                  │
│                                                                       │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐ │
│  │   Frontend   │◄────────►│   Backend    │◄────────►│  PostgreSQL │ │
│  │   (Svelte)   │   HTTP  │   (GoLang)   │   SQL   │  Database   │ │
│  │   Port:3000  │         │   Port:8080  │         │  Port:5432  │ │
│  └──────────────┘         └──────┬───────┘         └──────────────┘ │
│                                   │                                   │
│                            ┌──────▼───────┐                          │
│                            │    Redis     │                          │
│                            │   (Cache)    │                          │
│                            │  Port:6379   │                          │
│                            └──────┬───────┘                          │
│                                   │                                   │
│                            ┌──────▼───────┐                          │
│                            │  MQTT Broker │                          │
│                            │  (Mosquitto) │                          │
│                            │  Port:1883   │                          │
│                            └──────────────┘                          │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │
                                    │ HTTPS / MQTT
                                    │
┌───────────────────────────────────▼───────────────────────────────────┐
│                         EDGE LAYER                                     │
│                                                                         │
│  ┌──────────────┐                                                     │
│  │  ESP32 Device│                                                     │
│  │   (Brace)    │                                                     │
│  │  + Sensors   │                                                     │
│  │  + TinyML    │                                                     │
│  └──────┬───────┘                                                     │
│         │                                                              │
│         │ MQTT / HTTPS                                                 │
│         │                                                              │
└─────────┴──────────────────────────────────────────────────────────────┘
```

### 2.2 Padrões Arquiteturais

#### Backend (Clean Architecture)

```
backend/
├── cmd/api/              # Entry point (main.go)
├── internal/
│   ├── config/          # Configurações
│   ├── database/        # Migrations e conexão
│   ├── models/          # Entidades de domínio
│   ├── handlers/        # Controllers HTTP
│   ├── services/        # Lógica de negócio
│   └── middleware/      # Middleware HTTP
└── pkg/
    └── validators/      # Utilitários reutilizáveis
```

**Camadas**:
1. **Handlers**: Recebem requisições HTTP, validam entrada, chamam services
2. **Services**: Contêm lógica de negócio, orquestram operações
3. **Models**: Estruturas de dados, métodos de domínio
4. **Database**: Acesso a dados, migrations

---

## 3. Componentes Principais

### 3.1 Backend (GoLang)

#### 3.1.1 Serviços Principais

**IoTService** (`internal/services/iot_service.go`)
- **Responsabilidade**: Processamento de telemetria, gerenciamento de dispositivos
- **Principais Métodos**:
  - `ProcessTelemetry()`: Processa dados de sensores recebidos
  - `UpdateDeviceStatus()`: Atualiza status do dispositivo
  - `UpdateDeviceHeartbeat()`: Atualiza heartbeat do dispositivo
  - `SendCommand()`: Envia comandos para dispositivos via MQTT
  - `ProcessCommandResponse()`: Processa respostas de comandos
  - `ProcessDeviceAlert()`: Processa alertas originados do dispositivo
  - `GetConnectedDevices()`: Lista dispositivos conectados
  - `GetDeviceStatus()`: Obtém status atual do dispositivo

**AlertService** (`internal/services/alert_service.go`)
- **Responsabilidade**: Gerenciamento de alertas do sistema
- **Principais Métodos**:
  - `CreateAlert()`: Cria novo alerta (com deduplicação)
  - `GetAlerts()`: Lista alertas com filtros
  - `ResolveAlert()`: Resolve um alerta
  - `GetActiveAlerts()`: Lista alertas não resolvidos
  - `GetAlertStatistics()`: Estatísticas de alertas

**MQTTService** (`internal/services/mqtt_service.go`)
- **Responsabilidade**: Comunicação MQTT com dispositivos
- **Funcionalidades**:
  - Conexão com broker MQTT
  - Publicação de comandos
  - Subscrição a tópicos de telemetria
  - Processamento de mensagens

#### 3.1.2 Handlers HTTP

**AuthHandler** (`internal/handlers/auth_handler.go`)
- Endpoint: `POST /api/v1/auth/login`
- Autentica usuários e retorna token JWT

**PatientHandler** (`internal/handlers/patient_handler.go`)
- Endpoints CRUD para pacientes
- Validações robustas de dados

**BraceHandler** (`internal/handlers/brace_handler.go`)
- Endpoints CRUD para dispositivos (braces)
- Validações de device_id, MAC address, serial number

**IoTHandler** (`internal/handlers/iot_handler.go`)
- Endpoints para telemetria e comandos
- `POST /api/v1/devices/telemetry`: Recebe telemetria
- `POST /api/v1/devices/status`: Atualiza status
- `POST /api/v1/devices/alerts`: Recebe alertas do dispositivo
- `POST /api/v1/braces/:id/commands`: Envia comandos

**AdminHandler** (`internal/handlers/admin_handler.go`)
- Dashboard e relatórios
- Estatísticas e analytics

#### 3.1.3 Middleware

**AuthMiddleware** (`internal/middleware/auth.go`)
- Validação de token JWT
- Extração de claims (user_id, institution_id, role)

**DeviceAuthMiddleware** (`internal/middleware/device_auth.go`)
- Autenticação de dispositivos via API key
- Validação de credenciais de dispositivo

### 3.2 Modelos de Dados

#### 3.2.1 Entidades Principais

**Patient** (`internal/models/patient.go`)
```go
type Patient struct {
    ID                      uint
    UUID                    uuid.UUID
    ExternalID              string      // ID da AACD
    InstitutionID           uint
    MedicalStaffID          *uint
    
    // Dados Pessoais
    Name                    string
    DateOfBirth             *time.Time
    Gender                  string      // M/F
    CPF                     string
    Email                   string
    Phone                   string
    GuardianName            string
    GuardianPhone           string
    
    // Dados Médicos
    MedicalRecord           string
    DiagnosisCode           string
    SeverityLevel           int         // 1-5
    ScoliosisType           string
    
    // Prescrição
    PrescriptionHours       int         // Horas/dia
    DailyUsageTargetMinutes int         // Minutos/dia
    TreatmentStart          time.Time
    TreatmentEnd            *time.Time
    PrescriptionNotes       string
    
    // Status
    Status                  string      // active, inactive, completed, suspended
    IsActive                bool
    NextAppointment         *time.Time
}
```

**Brace** (`internal/models/brace.go`)
```go
type Brace struct {
    ID              uint
    UUID            uuid.UUID
    PatientID       *uint
    
    // Identificação
    DeviceID        string      // ID único do ESP32
    SerialNumber    string
    MacAddress      string
    
    // Status
    Status          DeviceStatus    // online, offline, maintenance, etc.
    BatteryLevel    *int            // 0-100
    BatteryVoltage  *float32
    SignalStrength  *int            // RSSI
    LastHeartbeat   *time.Time
    LastSeen        *time.Time
    
    // Firmware
    FirmwareVersion string
    HardwareVersion string
    Config          DeviceConfig    // JSONB
    CalibrationData DeviceConfig
    
    // Estatísticas
    TotalUsageHours float32
    LastUsageStart  *time.Time
    LastUsageEnd    *time.Time
}
```

**SensorReading** (`internal/models/sensor_reading.go`)
```go
type SensorReading struct {
    ID              uint
    UUID            uuid.UUID
    BraceID         uint
    PatientID       *uint
    SessionID       *uint
    Timestamp       time.Time
    
    // Sensores MPU6050
    AccelX          *float64
    AccelY          *float64
    AccelZ          *float64
    GyroX           *float64
    GyroY           *float64
    GyroZ           *float64
    MovementDetected bool
    
    // DHT22
    Temperature     *float64
    Humidity        *float64
    
    // FSR (Pressão)
    PressureDetected bool
    PressureValue    *int
    
    // Hall Effect
    BraceClosed     bool
    
    // Análise
    IsWearing       bool
    ConfidenceLevel ConfidenceLevel  // low, medium, high
}
```

**UsageSession** (`internal/models/usage_session.go`)
```go
type UsageSession struct {
    ID                uint
    UUID              uuid.UUID
    PatientID         uint
    BraceID           uint
    
    StartTime         time.Time
    EndTime           *time.Time
    Duration          *int           // segundos
    IsActive          bool
    
    // Métricas
    ComplianceScore   float32        // 0-100
    ComfortScore      float32
    PostureScore      float32
    MovementScore     float32
    
    // Estatísticas
    AvgAcceleration   float32
    MaxAcceleration   float32
    GoodPosturePct    float32
    PostureAlerts     int
}
```

**Alert** (`internal/models/alert.go`)
```go
type Alert struct {
    ID          uint
    UUID        uuid.UUID
    PatientID   *uint
    BraceID     *uint
    SessionID   *uint
    
    Type        AlertType      // battery_low, compliance_low, etc.
    Severity    Severity        // low, medium, high, critical
    Title       string
    Message     string
    Value       *float64
    Threshold   *float64
    
    Resolved    bool
    ResolvedAt  *time.Time
    ResolvedBy  *uint
    Notes       string
}
```

### 3.3 Validações

O sistema possui um pacote robusto de validadores (`pkg/validators/`):

- **CPF**: Validação com dígitos verificadores
- **Email**: Regex validation
- **Phone**: Telefone brasileiro (10-11 dígitos)
- **DeviceID**: Formato e comprimento
- **MAC Address**: Formato XX:XX:XX:XX:XX:XX
- **Battery Level**: Range 0-100
- **Severity Level**: Range 1-5
- **Prescription Hours**: Range 1-24

---

## 4. Fluxos de Dados

### 4.1 Fluxo de Telemetria (Principal)

```
1. ESP32 Device
   └─> Coleta dados dos sensores (acelerômetro, giroscópio, temperatura, etc.)
   └─> Processa localmente (TinyML para detecção de uso)
   └─> Envia telemetria via MQTT (tópico: orthotrack/{device_id}/telemetry)
   └─> Ou envia via HTTPS (POST /api/v1/devices/telemetry) como fallback

2. Backend API
   └─> Recebe telemetria via MQTT ou HTTP no IoTHandler.ReceiveTelemetry()
   └─> Valida autenticação do dispositivo
   └─> Chama IoTService.ProcessTelemetry()
   └─> Busca dispositivo no banco (por device_id)
   └─> Atualiza status (battery, signal, last_heartbeat)
   └─> Cria SensorReading no banco
   └─> Processa alertas (bateria baixa, temperatura, etc.)
   └─> Atualiza sessão de uso (se necessário)
   └─> Cache no Redis (últimos dados)
   └─> Publica via Redis pub/sub para WebSocket

3. Frontend Dashboard
   └─> Conecta via WebSocket ou polling
   └─> Recebe dados em tempo real
   └─> Atualiza visualizações
```

### 4.2 Fluxo de Comandos

```
1. Admin via Dashboard
   └─> Envia comando (ex: atualizar configuração)
   └─> POST /api/v1/braces/:id/commands

2. Backend API
   └─> Valida autenticação JWT
   └─> Cria BraceCommand no banco (status: pending)
   └─> Chama IoTService.SendCommand()
   └─> Publica comando via MQTT (tópico: orthotrack/{device_id}/commands)

3. ESP32 Device
   └─> Recebe comando via MQTT
   └─> Executa ação (ex: atualiza configuração)
   └─> Envia resposta via MQTT (tópico: orthotrack/{device_id}/commands/response)
   └─> Ou via HTTPS (POST /api/v1/devices/commands/response)

4. Backend API
   └─> Processa resposta
   └─> Atualiza BraceCommand (status: completed/failed)
   └─> Atualiza configuração do dispositivo (se aplicável)
```

### 4.3 Fluxo de Alertas

```
1. Detecção de Alerta
   └─> IoTService.processAlerts() (bateria baixa, temperatura)
   └─> Ou ESP32 detecta problema e envia alerta
   └─> POST /api/v1/devices/alerts

2. Backend API
   └─> Recebe alerta
   └─> Chama AlertService.CreateAlert()
   └─> Verifica duplicatas (alerta similar nas últimas 2h)
   └─> Cria Alert no banco
   └─> Cache no Redis
   └─> Publica via Redis pub/sub

3. Notificações
   └─> Processa notificações (email, SMS, push) em background
   └─> Envia para profissionais de saúde

4. Dashboard
   └─> Exibe alertas em tempo real
   └─> Permite resolução de alertas
```

### 4.4 Fluxo de Sessões de Uso

```
1. Detecção de Uso
   └─> SensorReading indica IsWearing = true
   └─> IoTService.updateUsageSession()

2. Criação de Sessão
   └─> Verifica se há sessão ativa
   └─> Se não, cria nova UsageSession
   └─> Status: active, AutoDetected: true

3. Durante a Sessão
   └─> SensorReadings são associados à sessão (SessionID)
   └─> Métricas são calculadas (posture, comfort, movement)

4. Fim da Sessão
   └─> SensorReading indica IsWearing = false
   └─> Finaliza sessão (EndTime, Duration, IsActive: false)
   └─> Calcula scores finais

5. Daily Compliance
   └─> Agrega sessões do dia
   └─> Calcula compliance percentual
   └─> Gera DailyCompliance record
```

---

## 5. Modelos de Dados

### 5.1 Relacionamentos

```
Institution (1) ──< (N) MedicalStaff
Institution (1) ──< (N) Patient
MedicalStaff (1) ──< (N) Patient
Patient (1) ──< (N) Brace
Patient (1) ──< (N) UsageSession
Brace (1) ──< (N) SensorReading
Brace (1) ──< (N) BraceCommand
Brace (1) ──< (N) Alert
UsageSession (1) ──< (N) SensorReading
UsageSession (1) ──< (N) Alert
Patient (1) ──< (N) DailyCompliance
```

### 5.2 Índices Principais

- `patients.external_id` (unique)
- `patients.medical_record` (unique)
- `braces.device_id` (unique)
- `braces.serial_number` (unique)
- `braces.mac_address` (unique)
- `sensor_readings.brace_id, timestamp` (composite)
- `usage_sessions.patient_id, start_time`
- `alerts.brace_id, created_at`

---

## 6. APIs e Endpoints

### 6.1 Autenticação

#### POST /api/v1/auth/login
Autentica usuário e retorna token JWT.

**Request**:
```json
{
  "email": "doctor@aacd.org.br",
  "password": "senha123"
}
```

**Response**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_at": "2024-01-15T10:30:00Z",
  "user": {
    "id": 1,
    "uuid": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Dr. João Silva",
    "email": "doctor@aacd.org.br",
    "role": "physician",
    "institution_id": 1
  }
}
```

### 6.2 Pacientes

#### GET /api/v1/patients
Lista pacientes com paginação e filtros.

**Query Parameters**:
- `page`: Número da página (default: 1)
- `limit`: Itens por página (default: 20)
- `institution_id`: Filtrar por instituição
- `status`: Filtrar por status (active, inactive, etc.)
- `is_active`: true/false
- `search`: Busca em name, external_id, medical_record

#### POST /api/v1/patients
Cria novo paciente.

**Request**:
```json
{
  "external_id": "AACD-001",
  "name": "João da Silva",
  "date_of_birth": "2010-05-15",
  "gender": "M",
  "cpf": "12345678909",
  "email": "joao@example.com",
  "phone": "11987654321",
  "medical_record": "PRT-001",
  "diagnosis_code": "M41.9",
  "severity_level": 3,
  "prescription_hours": 16,
  "daily_usage_target_minutes": 960
}
```

#### GET /api/v1/patients/:id
Obtém detalhes de um paciente.

#### PUT /api/v1/patients/:id
Atualiza paciente.

#### DELETE /api/v1/patients/:id
Remove paciente (soft delete).

### 6.3 Dispositivos (Braces)

#### GET /api/v1/braces
Lista dispositivos.

#### POST /api/v1/braces
Cria novo dispositivo.

**Request**:
```json
{
  "device_id": "ESP32-001",
  "serial_number": "SN-2024-001",
  "mac_address": "AA:BB:CC:DD:EE:FF",
  "model": "ESP32-ORTHO-V1",
  "version": "1.0",
  "patient_id": 1
}
```

#### GET /api/v1/braces/:id
Obtém detalhes de um dispositivo.

#### PUT /api/v1/braces/:id
Atualiza dispositivo.

#### DELETE /api/v1/braces/:id
Remove dispositivo.

### 6.4 Telemetria e Comandos (Dispositivos)

#### POST /api/v1/devices/telemetry
Recebe telemetria de dispositivo.

**Headers**:
- `X-Device-API-Key`: API key do dispositivo

**Request**:
```json
{
  "device_id": "ESP32-001",
  "timestamp": "2024-01-15T10:30:00Z",
  "sensors": {
    "accelerometer": {
      "type": "accelerometer",
      "value": {"x": 0.5, "y": -0.2, "z": 9.8},
      "unit": "m/s²"
    },
    "temperature": {
      "type": "temperature",
      "value": 25.5,
      "unit": "°C"
    }
  },
  "battery_level": 85,
  "status": "online"
}
```

#### POST /api/v1/devices/status
Atualiza status do dispositivo.

#### POST /api/v1/devices/alerts
Recebe alerta do dispositivo.

#### POST /api/v1/devices/commands/response
Recebe resposta de comando.

#### POST /api/v1/braces/:id/commands
Envia comando para dispositivo.

**Request**:
```json
{
  "command_type": "update_config",
  "parameters": {
    "sample_rate": 10,
    "deep_sleep_enabled": false
  },
  "priority": "normal"
}
```

#### GET /api/v1/braces/:id/commands
Lista comandos de um dispositivo.

### 6.5 Alertas

#### GET /api/v1/alerts
Lista alertas com filtros.

**Query Parameters**:
- `patient_id`: Filtrar por paciente
- `brace_id`: Filtrar por dispositivo
- `severity`: Filtrar por severidade
- `resolved`: true/false
- `page`, `limit`: Paginação

#### PUT /api/v1/alerts/:id/resolve
Resolve um alerta.

**Request**:
```json
{
  "notes": "Problema resolvido"
}
```

#### GET /api/v1/alerts/statistics
Estatísticas de alertas.

**Query Parameters**:
- `period`: Período (ex: "24h", "7d", "30d")

### 6.6 Dashboard e Relatórios

#### GET /api/v1/dashboard/overview
Visão geral do dashboard.

**Response**:
```json
{
  "total_patients": 150,
  "active_patients": 120,
  "total_braces": 130,
  "online_braces": 95,
  "active_alerts": 5,
  "today_sessions": 45,
  "avg_compliance_today": 87.5
}
```

#### GET /api/v1/dashboard/realtime
Dados em tempo real.

**Query Parameters**:
- `device_id`: Dispositivo específico (opcional)

#### GET /api/v1/reports/compliance
Relatório de compliance.

**Query Parameters**:
- `patient_id`: Filtrar por paciente
- `start_date`: Data inicial (YYYY-MM-DD)
- `end_date`: Data final (YYYY-MM-DD)

#### GET /api/v1/reports/usage
Relatório de uso.

---

## 7. Processamento de Dados

### 7.1 Processamento de Telemetria

O `IoTService.ProcessTelemetry()` realiza:

1. **Busca do Dispositivo**: Localiza `Brace` por `device_id`
2. **Atualização de Status**: Atualiza `LastHeartbeat`, `BatteryLevel`, `Status`
3. **Criação de SensorReading**: Converte `TelemetryData` em `SensorReading`
4. **Cálculo de Uso**: Chama `CalculateWearing()` para determinar se está usando
5. **Processamento de Alertas**: Verifica condições de alerta
6. **Atualização de Sessão**: Cria ou atualiza `UsageSession`
7. **Cache**: Armazena no Redis para acesso rápido
8. **Pub/Sub**: Publica para WebSocket clients

### 7.2 Cálculo de Compliance

**Daily Compliance** é calculado:

```go
CompliancePercent = (ActualMinutes / TargetMinutes) * 100
IsCompliant = CompliancePercent >= 80.0
```

**Scores de Sessão**:
- `ComplianceScore`: Baseado em duração vs. prescrição
- `ComfortScore`: Baseado em ajustes e pressão
- `PostureScore`: Baseado em análise de postura
- `QualityScore`: Média ponderada dos scores

### 7.3 Detecção de Uso

O método `SensorReading.CalculateWearing()` usa:

1. **Pressão + Fechamento**: Se ambos detectados → `ConfidenceHigh`
2. **Pressão OU Fechamento**: Se apenas um → `ConfidenceMedium`
3. **Movimento**: Se detectado → `ConfidenceLow` ou aumenta confiança

---

## 8. Sistema de Alertas

### 8.1 Tipos de Alertas

- `battery_low`: Bateria abaixo do threshold
- `compliance_low`: Compliance abaixo de 80%
- `temperature_high`: Temperatura acima do limite
- `temperature_low`: Temperatura abaixo do limite
- `device_offline`: Dispositivo offline por muito tempo
- `sensor_error`: Erro em sensor
- `firmware_update`: Atualização de firmware disponível
- `usage_anomaly`: Anomalia no padrão de uso
- `maintenance_required`: Manutenção necessária

### 8.2 Severidades

- `low`: Informativo
- `medium`: Atenção necessária
- `high`: Ação imediata recomendada
- `critical`: Ação imediata obrigatória

### 8.3 Processamento de Alertas

1. **Deduplicação**: Verifica alertas similares nas últimas 2 horas
2. **Criação**: Cria `Alert` no banco
3. **Cache**: Armazena no Redis
4. **Pub/Sub**: Publica para clients em tempo real
5. **Notificações**: Processa notificações em background (email, SMS, push)

### 8.4 Thresholds Configuráveis

```go
AlertThresholds{
    BatteryLow:     20,      // %
    ComplianceLow:  80.0,    // %
    TempHigh:       40.0,    // °C
    TempLow:        5.0,     // °C
    OfflineTimeout: 120,     // minutos
}
```

---

## 9. Autenticação e Segurança

### 9.1 Autenticação de Usuários

- **Método**: JWT (JSON Web Tokens)
- **Algoritmo**: HS256
- **Expiração**: Configurável (default: 24h)
- **Claims**: `user_id`, `institution_id`, `role`, `email`

**Fluxo**:
1. Usuário faz login com email/senha
2. Backend valida credenciais (bcrypt)
3. Gera JWT token
4. Token é enviado no header: `Authorization: Bearer <token>`
5. Middleware valida token em cada requisição

### 9.2 Autenticação de Dispositivos

- **Método**: API Key
- **Header**: `X-Device-API-Key`
- **Validação**: Verifica API key no banco de dados

### 9.3 Segurança de Dados

- **Senhas**: Hash com bcrypt (cost: 10)
- **HTTPS**: Obrigatório em produção
- **CORS**: Configurado para origens permitidas
- **Validação**: Input validation em todos os endpoints
- **Rate Limiting**: (a implementar)
- **Logs de Auditoria**: Timestamps em todas as operações

---

## 10. Integrações

### 10.1 MQTT

**Broker**: Eclipse Mosquitto

**Tópicos**:
- `orthotrack/{device_id}/telemetry`: Telemetria do dispositivo
- `orthotrack/{device_id}/commands`: Comandos para dispositivo
- `orthotrack/{device_id}/status`: Status do dispositivo
- `orthotrack/{device_id}/alerts`: Alertas do dispositivo

**QoS**: 1 (at least once delivery)

### 10.2 Redis

**Uso**:
- **Cache**: Dados frequentes (telemetria recente, alertas ativos)
- **Pub/Sub**: WebSocket em tempo real
- **Sessões**: (futuro)

**Chaves**:
- `telemetry:{device_id}`: Última telemetria (TTL: 1h)
- `alerts:active`: Lista de alertas ativos (TTL: 5min)
- `alert:{alert_id}`: Cache de alerta (TTL: 24h)

**Canais Pub/Sub**:
- `realtime:telemetry:{device_id}`: Telemetria em tempo real
- `realtime:telemetry`: Canal geral
- `realtime:alerts`: Alertas em tempo real
- `realtime:alerts:resolved`: Resolução de alertas

### 10.3 IA (Futuro)

- **OpenAI API**: Análise avançada de padrões
- **DeepSeek API**: Alternativa de IA
- **Cache**: Respostas de IA por 24h

---

## 11. Deploy e Operação

### 11.1 Variáveis de Ambiente

```env
# Servidor
PORT=8080

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=orthotrack_v3
DB_USER=orthotrack
DB_PASSWORD=password
DB_SSL_MODE=disable

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT
JWT_SECRET=your-secret-key-here
JWT_EXPIRE_HOURS=24

# MQTT
MQTT_BROKER_URL=tcp://localhost:1883
MQTT_CLIENT_ID=orthotrack-backend
MQTT_USERNAME=
MQTT_PASSWORD=

# AI (Opcional)
OPENAI_API_KEY=
DEEPSEEK_API_KEY=
AI_DEFAULT_MODEL=openai

# Alert Thresholds
ALERT_BATTERY_LOW=20
ALERT_COMPLIANCE_LOW=80
ALERT_TEMP_HIGH=40
ALERT_TEMP_LOW=5
ALERT_OFFLINE_TIMEOUT=120

# IoT
IOT_GATEWAY_ENABLED=true
TELEMETRY_RETENTION_DAYS=30
```

### 11.2 Migrations

```bash
# As migrations são executadas automaticamente na inicialização
# Ou manualmente:
go run cmd/api/main.go
```

### 11.3 Docker

```bash
# Build
docker build -t orthotrack-api:v3 ./backend

# Run
docker run -p 8080:8080 \
  -e DB_HOST=postgres \
  -e REDIS_HOST=redis \
  orthotrack-api:v3
```

### 11.4 Health Check

**Endpoint**: `GET /api/v1/health`

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "3.0.0"
}
```

### 11.5 Logs

- **Formato**: Texto estruturado
- **Níveis**: Info, Warning, Error
- **Rotação**: (configurar)

### 11.6 Monitoramento

- **Métricas**: (a implementar)
- **Alertas de Sistema**: (a implementar)
- **Performance**: (a implementar)

---

## 12. Documentação Swagger

A documentação Swagger está disponível em:

**URL**: `http://localhost:8080/swagger/index.html`

Para gerar/atualizar a documentação:

```bash
cd backend
swag init -g cmd/api/main.go
```

---

## 13. Testes

### 13.1 Testes Unitários

```bash
# Executar todos os testes
go test ./...

# Testes de validators
go test ./pkg/validators/... -v

# Com cobertura
go test ./... -cover
```

### 13.2 Testes de Integração

(a implementar)

---

## 14. Próximos Passos

### Melhorias Planejadas

1. **Testes**: Expandir cobertura de testes
2. **Documentação Swagger**: Completar anotações em todos os endpoints
3. **Rate Limiting**: Implementar rate limiting nas APIs
4. **Métricas**: Adicionar Prometheus metrics
5. **Logging**: Implementar logging estruturado (Zap)
6. **WebSocket**: Implementar WebSocket para dados em tempo real
7. **IA**: Integrar OpenAI/DeepSeek para análises avançadas
8. **Notificações**: Implementar sistema completo de notificações

---

## 15. Referências

- **Documentação Go**: https://go.dev/doc/
- **Gin Framework**: https://gin-gonic.com/docs/
- **GORM**: https://gorm.io/docs/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Redis**: https://redis.io/docs/
- **MQTT**: https://mqtt.org/
- **Swagger**: https://swagger.io/

---

**Versão do Documento**: 1.0  
**Última Atualização**: Janeiro 2024  
**Autor**: Equipe OrthoTrack IoT Platform v3









