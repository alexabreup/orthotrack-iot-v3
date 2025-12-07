# Backend Technical Specifications - GoLang API

## 🏗️ Arquitetura Geral

### Stack Tecnológico
- **Language**: Go 1.21+
- **Framework**: Gin HTTP Framework
- **Database**: PostgreSQL 14+
- **Cache**: Redis 6+
- **Message Queue**: MQTT (Eclipse Paho)
- **Auth**: JWT (golang-jwt/jwt)
- **ORM**: GORM v2
- **Validation**: go-playground/validator

### Estrutura do Projeto
```
backend/
├── cmd/
│   └── api/
│       └── main.go              # Entry point
├── internal/                    # Private application code
│   ├── config/                  # Configuration management
│   ├── database/               # Database connection & migrations
│   ├── handlers/               # HTTP handlers
│   ├── middleware/             # HTTP middleware
│   ├── models/                 # Data models
│   ├── services/               # Business logic
│   ├── repositories/           # Data access layer
│   └── utils/                  # Utility functions
├── pkg/                        # Public libraries
│   ├── auth/                   # Authentication utilities
│   ├── logger/                 # Logging utilities
│   └── validators/             # Custom validators
├── migrations/                 # Database migrations
├── tests/                      # Test files
└── docs/                      # API documentation
```

---

## 📊 Modelos de Dados

### Entidades Principais

#### 1. Patient (Paciente)
```go
type Patient struct {
    ID          uint      `json:"id" gorm:"primaryKey"`
    ExternalID  string    `json:"external_id" gorm:"uniqueIndex"` // ID da AACD
    Name        string    `json:"name" gorm:"not null"`
    DateOfBirth time.Time `json:"date_of_birth"`
    Gender      string    `json:"gender" gorm:"type:varchar(1)"`
    CPF         string    `json:"cpf" gorm:"uniqueIndex"`
    
    // Medical Info
    DiagnosisCode    string    `json:"diagnosis_code"`
    SeverityLevel    int       `json:"severity_level"` // 1-5
    PrescriptionHours int      `json:"prescription_hours"` // Horas/dia prescritas
    TreatmentStart   time.Time `json:"treatment_start"`
    TreatmentEnd     *time.Time `json:"treatment_end,omitempty"`
    
    // Contact Info
    Email       string `json:"email"`
    Phone       string `json:"phone"`
    GuardianName string `json:"guardian_name,omitempty"`
    GuardianPhone string `json:"guardian_phone,omitempty"`
    
    // Relationships
    InstitutionID uint     `json:"institution_id"`
    Institution   Institution `json:"institution" gorm:"foreignKey:InstitutionID"`
    Braces       []Brace   `json:"braces"`
    
    // Metadata
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
    DeletedAt *time.Time `json:"deleted_at,omitempty" gorm:"index"`
}
```

#### 2. Brace (Colete/Dispositivo)
```go
type Brace struct {
    ID           uint   `json:"id" gorm:"primaryKey"`
    SerialNumber string `json:"serial_number" gorm:"uniqueIndex"`
    DeviceID     string `json:"device_id"` // ESP32 MAC address
    Model        string `json:"model"`
    Version      string `json:"version"`
    
    // Assignment
    PatientID uint     `json:"patient_id"`
    Patient   Patient  `json:"patient" gorm:"foreignKey:PatientID"`
    
    // Device Status
    Status          string    `json:"status"` // active, inactive, maintenance
    BatteryLevel    int       `json:"battery_level"`
    LastHeartbeat   time.Time `json:"last_heartbeat"`
    FirmwareVersion string    `json:"firmware_version"`
    
    // Calibration
    CalibrationData JSON     `json:"calibration_data" gorm:"type:jsonb"`
    LastCalibration time.Time `json:"last_calibration"`
    
    // Relationships
    SensorReadings []SensorReading `json:"sensor_readings"`
    Alerts        []Alert         `json:"alerts"`
    
    // Metadata
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
    DeletedAt *time.Time `json:"deleted_at,omitempty" gorm:"index"`
}
```

#### 3. SensorReading (Leitura de Sensores)
```go
type SensorReading struct {
    ID      uint `json:"id" gorm:"primaryKey"`
    BraceID uint `json:"brace_id"`
    Brace   Brace `json:"brace" gorm:"foreignKey:BraceID"`
    
    // Timestamp
    Timestamp time.Time `json:"timestamp" gorm:"index"`
    
    // Accelerometer Data (MPU6050)
    AccelX float64 `json:"accel_x"`
    AccelY float64 `json:"accel_y"`
    AccelZ float64 `json:"accel_z"`
    GyroX  float64 `json:"gyro_x"`
    GyroY  float64 `json:"gyro_y"`
    GyroZ  float64 `json:"gyro_z"`
    
    // Environmental
    Temperature float64 `json:"temperature"`
    Humidity    float64 `json:"humidity"`
    
    // Pressure Sensors (Force Sensitive Resistors)
    PressurePoints JSON `json:"pressure_points" gorm:"type:jsonb"`
    
    // Device Status
    BatteryVoltage float64 `json:"battery_voltage"`
    SignalStrength int     `json:"signal_strength"`
    
    // Processed Data
    IsWearing       bool    `json:"is_wearing"`       // AI/ML detection
    MovementLevel   string  `json:"movement_level"`   // low, medium, high
    PostureScore    float64 `json:"posture_score"`    // 0-100
    ComfortLevel    string  `json:"comfort_level"`    // comfortable, tight, loose
    
    CreatedAt time.Time `json:"created_at"`
}
```

#### 4. Alert (Alertas)
```go
type Alert struct {
    ID          uint   `json:"id" gorm:"primaryKey"`
    Type        string `json:"type"` // battery_low, compliance_low, device_offline, etc.
    Severity    string `json:"severity"` // info, warning, error, critical
    Title       string `json:"title"`
    Message     string `json:"message"`
    
    // Source
    BraceID   *uint  `json:"brace_id,omitempty"`
    Brace     *Brace `json:"brace,omitempty" gorm:"foreignKey:BraceID"`
    PatientID *uint  `json:"patient_id,omitempty"`
    Patient   *Patient `json:"patient,omitempty" gorm:"foreignKey:PatientID"`
    
    // Status
    Status       string    `json:"status"` // open, acknowledged, resolved, dismissed
    AcknowledgedBy uint    `json:"acknowledged_by,omitempty"`
    AcknowledgedAt *time.Time `json:"acknowledged_at,omitempty"`
    ResolvedAt     *time.Time `json:"resolved_at,omitempty"`
    
    // Additional Data
    MetaData JSON `json:"metadata" gorm:"type:jsonb"`
    
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}
```

#### 5. UsageSession (Sessões de Uso)
```go
type UsageSession struct {
    ID        uint `json:"id" gorm:"primaryKey"`
    BraceID   uint `json:"brace_id"`
    Brace     Brace `json:"brace" gorm:"foreignKey:BraceID"`
    PatientID uint `json:"patient_id"`
    Patient   Patient `json:"patient" gorm:"foreignKey:PatientID"`
    
    // Session Info
    StartTime    time.Time  `json:"start_time"`
    EndTime      *time.Time `json:"end_time,omitempty"`
    Duration     int        `json:"duration"` // seconds
    IsActive     bool       `json:"is_active"`
    
    // Analytics
    AvgMovementLevel string  `json:"avg_movement_level"`
    AvgPostureScore  float64 `json:"avg_posture_score"`
    ComplianceScore  float64 `json:"compliance_score"` // 0-100
    
    // Comfort Analysis
    ComfortIssues    JSON `json:"comfort_issues" gorm:"type:jsonb"`
    AdjustmentNeeded bool `json:"adjustment_needed"`
    
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}
```

---

## 🔌 APIs e Endpoints

### Authentication & Authorization

#### JWT Authentication
```go
// JWT Claims Structure
type Claims struct {
    UserID   uint   `json:"user_id"`
    Email    string `json:"email"`
    Role     string `json:"role"`
    jwt.RegisteredClaims
}

// Middleware
func JWTAuthMiddleware() gin.HandlerFunc {
    return gin.HandlerFunc(func(c *gin.Context) {
        // Token validation logic
    })
}
```

### Core API Endpoints

#### Patients API
```
GET    /api/v1/patients              # List patients (paginated)
POST   /api/v1/patients              # Create patient
GET    /api/v1/patients/:id          # Get patient by ID
PUT    /api/v1/patients/:id          # Update patient
DELETE /api/v1/patients/:id          # Soft delete patient
GET    /api/v1/patients/:id/compliance # Get compliance data
GET    /api/v1/patients/:id/sessions # Get usage sessions
```

#### Devices/Braces API
```
GET    /api/v1/braces                # List all braces
POST   /api/v1/braces                # Register new brace
GET    /api/v1/braces/:id            # Get brace details
PUT    /api/v1/braces/:id            # Update brace
POST   /api/v1/braces/:id/calibrate  # Calibrate device
GET    /api/v1/braces/:id/status     # Real-time status
```

#### Telemetry API
```
POST   /api/v1/telemetry             # Receive sensor data (bulk)
GET    /api/v1/telemetry/:brace_id   # Get historical data
GET    /api/v1/telemetry/:brace_id/live # WebSocket for real-time
```

#### Alerts API
```
GET    /api/v1/alerts                # List alerts (filtered)
POST   /api/v1/alerts                # Create manual alert
PUT    /api/v1/alerts/:id/acknowledge # Acknowledge alert
PUT    /api/v1/alerts/:id/resolve    # Resolve alert
```

---

## ⚡ Services e Business Logic

### IoT Service
```go
type IoTService interface {
    ProcessSensorData(data *TelemetryData) error
    DetectUsageState(readings []SensorReading) (*UsageState, error)
    CalculateCompliance(patientID uint, period time.Duration) (*ComplianceReport, error)
    GenerateInsights(patientID uint) (*PatientInsights, error)
}

type iotService struct {
    sensorRepo    SensorRepository
    alertService  AlertService
    aiService     AIService
    cache         Cache
}
```

### Alert Service
```go
type AlertService interface {
    CreateAlert(alert *Alert) error
    ProcessRules(braceID uint) error
    SendNotification(alert *Alert) error
    EscalateAlert(alertID uint) error
}

type alertService struct {
    alertRepo     AlertRepository
    notification  NotificationService
    rules         RuleEngine
}
```

### Analytics Service
```go
type AnalyticsService interface {
    CalculateComplianceScore(patientID uint, period time.Duration) (float64, error)
    GenerateUsageReport(patientID uint) (*UsageReport, error)
    PredictCompliance(patientID uint) (*CompliancePrediction, error)
    DetectAnomalies(braceID uint) ([]Anomaly, error)
}
```

---

## 🚀 Performance e Otimizações

### Database Optimization
```go
// Indexes
type SensorReading struct {
    // ...
    Timestamp time.Time `json:"timestamp" gorm:"index:idx_timestamp"`
    BraceID   uint      `json:"brace_id" gorm:"index:idx_brace_timestamp,priority:1"`
    //                                   gorm:"index:idx_timestamp,priority:2"`
}

// Partitioning Strategy (PostgreSQL)
// Partition by month for sensor_readings table
```

### Caching Strategy
```go
// Redis Cache Keys
const (
    PatientCacheKey    = "patient:%d"
    BraceStatusKey     = "brace:status:%d"
    ComplianceKey      = "compliance:%d:%s" // patientID:period
    RealtimeDataKey    = "realtime:%d"      // braceID
)

// Cache TTL
var CacheTTL = map[string]time.Duration{
    "patient":    1 * time.Hour,
    "compliance": 30 * time.Minute,
    "realtime":   10 * time.Second,
}
```

### Batch Processing
```go
// Bulk insert for sensor data
func (s *sensorService) BulkInsertReadings(readings []SensorReading) error {
    batchSize := 1000
    for i := 0; i < len(readings); i += batchSize {
        end := i + batchSize
        if end > len(readings) {
            end = len(readings)
        }
        
        if err := s.db.CreateInBatches(readings[i:end], batchSize).Error; err != nil {
            return err
        }
    }
    return nil
}
```

---

## 🔐 Segurança

### Data Encryption
```go
// Encrypt sensitive data at rest
func EncryptPII(data string) (string, error) {
    // AES-256-GCM encryption
}

// Hash passwords
func HashPassword(password string) (string, error) {
    return bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
}
```

### Rate Limiting
```go
// Rate limiting middleware
func RateLimitMiddleware() gin.HandlerFunc {
    limiter := rate.NewLimiter(rate.Every(time.Minute), 100) // 100 req/min
    return gin.HandlerFunc(func(c *gin.Context) {
        if !limiter.Allow() {
            c.JSON(429, gin.H{"error": "Rate limit exceeded"})
            c.Abort()
            return
        }
        c.Next()
    })
}
```

### Input Validation
```go
type CreatePatientRequest struct {
    Name        string `json:"name" validate:"required,min=2,max=100"`
    Email       string `json:"email" validate:"required,email"`
    CPF         string `json:"cpf" validate:"required,cpf"`
    DateOfBirth string `json:"date_of_birth" validate:"required,datetime=2006-01-02"`
}
```

---

## 📊 Monitoring e Observability

### Metrics
```go
// Prometheus metrics
var (
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )
    
    sensorDataPointsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "sensor_data_points_total",
            Help: "Total sensor data points received",
        },
        []string{"brace_id", "sensor_type"},
    )
)
```

### Health Checks
```go
// Health check endpoints
func (h *HealthHandler) LivenessCheck(c *gin.Context) {
    c.JSON(200, gin.H{"status": "alive"})
}

func (h *HealthHandler) ReadinessCheck(c *gin.Context) {
    // Check database connection
    // Check Redis connection
    // Check external services
}
```

---

## 🧪 Testing Strategy

### Unit Tests
```go
func TestPatientService_CreatePatient(t *testing.T) {
    // Given
    mockRepo := &mocks.PatientRepository{}
    service := NewPatientService(mockRepo)
    
    // When
    patient, err := service.CreatePatient(&CreatePatientRequest{
        Name: "Test Patient",
        Email: "test@example.com",
    })
    
    // Then
    assert.NoError(t, err)
    assert.NotNil(t, patient)
    mockRepo.AssertExpectations(t)
}
```

### Integration Tests
```go
func TestPatientAPI_Integration(t *testing.T) {
    // Setup test database
    // Create test server
    // Run API tests
}
```

### Load Tests
```go
// Using Go's testing package + tools like k6
func BenchmarkTelemetryEndpoint(b *testing.B) {
    // Benchmark telemetry data ingestion
}
```

---

## 🔧 Configuration

### Environment Variables
```go
type Config struct {
    Port        string `env:"PORT" envDefault:"8080"`
    Environment string `env:"ENVIRONMENT" envDefault:"development"`
    
    // Database
    DBHost     string `env:"DB_HOST" envDefault:"localhost"`
    DBPort     string `env:"DB_PORT" envDefault:"5432"`
    DBName     string `env:"DB_NAME" envDefault:"orthotrack"`
    DBUser     string `env:"DB_USER" envDefault:"orthotrack"`
    DBPassword string `env:"DB_PASSWORD"`
    
    // Redis
    RedisHost string `env:"REDIS_HOST" envDefault:"localhost"`
    RedisPort string `env:"REDIS_PORT" envDefault:"6379"`
    
    // JWT
    JWTSecret string `env:"JWT_SECRET"`
    
    // External APIs
    OpenAIAPIKey string `env:"OPENAI_API_KEY"`
    
    // MQTT
    MQTTBrokerURL string `env:"MQTT_BROKER_URL" envDefault:"tcp://localhost:1883"`
}
```

---

**Documentação Técnica - Backend GoLang**  
**Versão**: 1.0  
**Última Atualização**: 2024-12-03