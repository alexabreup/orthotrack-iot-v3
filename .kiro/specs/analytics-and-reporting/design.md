# Design Document - Sistema de Analytics e Relatórios

## Overview

O Sistema de Analytics e Relatórios é um módulo crítico do OrthoTrack IoT v3 que transforma dados brutos de telemetria em insights acionáveis para profissionais de saúde. O sistema processa grandes volumes de dados históricos, calcula métricas agregadas, gera visualizações interativas e produz relatórios exportáveis em múltiplos formatos.

### Objetivos Principais

1. **Performance**: Responder em menos de 2 segundos para consultas de até 1 ano de dados
2. **Escalabilidade**: Suportar análise simultânea de centenas de pacientes
3. **Usabilidade**: Interface intuitiva com visualizações claras e interativas
4. **Exportabilidade**: Gerar relatórios profissionais em PDF e Excel
5. **Precisão**: Cálculos corretos e consistentes de todas as métricas

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend (SvelteKit)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Dashboard   │  │   Charts     │  │   Export     │      │
│  │  Components  │  │  Components  │  │   Service    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP/REST
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend API (Go/Gin)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Analytics   │  │   Report     │  │    Cache     │      │
│  │   Handler    │  │  Generator   │  │   Manager    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │  Analytics   │  │  Aggregation │                        │
│  │   Service    │  │   Service    │                        │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
        ┌──────────────┐        ┌──────────────┐
        │  PostgreSQL  │        │    Redis     │
        │   Database   │        │    Cache     │
        └──────────────┘        └──────────────┘
```

### Component Responsibilities

**Frontend Components:**
- **Dashboard Components**: Renderizam cards, gráficos e estatísticas
- **Chart Components**: Visualizações interativas usando Chart.js ou similar
- **Export Service**: Gerencia downloads de PDF e Excel

**Backend Services:**
- **Analytics Handler**: Endpoints REST para consultas de analytics
- **Analytics Service**: Lógica de negócio para cálculos de métricas
- **Aggregation Service**: Queries otimizadas e agregações no banco
- **Report Generator**: Geração de PDFs e Excel
- **Cache Manager**: Gerenciamento de cache Redis

## Components and Interfaces

### Frontend Components

#### 1. PatientAnalyticsDashboard Component

```typescript
interface PatientAnalyticsDashboardProps {
  patientId: string;
  initialPeriod?: DateRange;
}

interface DateRange {
  startDate: Date;
  endDate: Date;
}

interface PatientMetrics {
  averageDailyUsage: number;
  totalSessions: number;
  averageSessionDuration: number;
  averageCompliance: number;
  currentStreak: number;
}
```

#### 2. ComplianceChart Component

```typescript
interface ComplianceChartProps {
  data: ComplianceDataPoint[];
  institutionAverage?: number;
}

interface ComplianceDataPoint {
  date: Date;
  compliance: number;
  usageHours: number;
  prescribedHours: number;
}
```

#### 3. UsagePatternCharts Component

```typescript
interface HourlyDistribution {
  hour: number; // 0-23
  minutes: number;
}

interface WeeklyDistribution {
  dayOfWeek: number; // 0-6 (Sunday-Saturday)
  averageHours: number;
}
```

#### 4. ExportButton Component

```typescript
interface ExportButtonProps {
  patientId: string;
  period: DateRange;
  format: 'pdf' | 'excel';
  onExportStart?: () => void;
  onExportComplete?: (fileUrl: string) => void;
  onExportError?: (error: Error) => void;
}
```

### Backend API Endpoints

#### Analytics Endpoints

```go
// GET /api/v1/analytics/patients/:id/metrics
type PatientMetricsRequest struct {
    PatientID  string    `uri:"id" binding:"required"`
    StartDate  time.Time `form:"start_date" binding:"required"`
    EndDate    time.Time `form:"end_date" binding:"required"`
}

type PatientMetricsResponse struct {
    AverageDailyUsage      float64 `json:"average_daily_usage"`
    TotalSessions          int     `json:"total_sessions"`
    AverageSessionDuration float64 `json:"average_session_duration"`
    AverageCompliance      float64 `json:"average_compliance"`
    CurrentStreak          int     `json:"current_streak"`
}

// GET /api/v1/analytics/patients/:id/compliance
type ComplianceDataResponse struct {
    Data []ComplianceDataPoint `json:"data"`
    InstitutionAverage float64 `json:"institution_average,omitempty"`
}

type ComplianceDataPoint struct {
    Date            time.Time `json:"date"`
    Compliance      float64   `json:"compliance"`
    UsageHours      float64   `json:"usage_hours"`
    PrescribedHours float64   `json:"prescribed_hours"`
}

// GET /api/v1/analytics/patients/:id/usage-patterns
type UsagePatternsResponse struct {
    HourlyDistribution  []HourlyUsage  `json:"hourly_distribution"`
    WeeklyDistribution  []WeeklyUsage  `json:"weekly_distribution"`
}

type HourlyUsage struct {
    Hour    int     `json:"hour"`
    Minutes int     `json:"minutes"`
}

type WeeklyUsage struct {
    DayOfWeek    int     `json:"day_of_week"`
    AverageHours float64 `json:"average_hours"`
}

// GET /api/v1/analytics/institution/dashboard
type InstitutionDashboardResponse struct {
    TotalActivePatients   int                      `json:"total_active_patients"`
    AverageCompliance     float64                  `json:"average_compliance"`
    DeviceStatus          DeviceStatusCounts       `json:"device_status"`
    LowestCompliance      []PatientComplianceSummary `json:"lowest_compliance"`
    HighestCompliance     []PatientComplianceSummary `json:"highest_compliance"`
    ComplianceDistribution ComplianceDistribution  `json:"compliance_distribution"`
}

type DeviceStatusCounts struct {
    Online      int `json:"online"`
    Offline     int `json:"offline"`
    Maintenance int `json:"maintenance"`
}

type PatientComplianceSummary struct {
    PatientID   string  `json:"patient_id"`
    PatientName string  `json:"patient_name"`
    Compliance  float64 `json:"compliance"`
}

type ComplianceDistribution struct {
    Below50     int `json:"below_50"`
    Between5070 int `json:"between_50_70"`
    Between7090 int `json:"between_70_90"`
    Above90     int `json:"above_90"`
}
```

#### Export Endpoints

```go
// POST /api/v1/reports/pdf
type PDFReportRequest struct {
    PatientID string    `json:"patient_id" binding:"required"`
    StartDate time.Time `json:"start_date" binding:"required"`
    EndDate   time.Time `json:"end_date" binding:"required"`
}

type ReportResponse struct {
    FileURL  string `json:"file_url"`
    FileName string `json:"file_name"`
    FileSize int64  `json:"file_size"`
}

// POST /api/v1/reports/excel
type ExcelReportRequest struct {
    PatientID string    `json:"patient_id" binding:"required"`
    StartDate time.Time `json:"start_date" binding:"required"`
    EndDate   time.Time `json:"end_date" binding:"required"`
}
```

## Data Models

### Analytics Aggregation Tables

Para otimizar performance, criaremos tabelas de agregação pré-calculadas:

```sql
-- Tabela de compliance diário (pré-agregado)
CREATE TABLE daily_compliance (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id),
    date DATE NOT NULL,
    usage_hours DECIMAL(5,2) NOT NULL,
    prescribed_hours DECIMAL(5,2) NOT NULL,
    compliance_percentage DECIMAL(5,2) NOT NULL,
    session_count INTEGER NOT NULL,
    average_session_duration DECIMAL(5,2),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(patient_id, date)
);

CREATE INDEX idx_daily_compliance_patient_date ON daily_compliance(patient_id, date DESC);
CREATE INDEX idx_daily_compliance_date ON daily_compliance(date DESC);

-- Tabela de distribuição horária (pré-agregado)
CREATE TABLE hourly_usage_distribution (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id),
    hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_minutes INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(patient_id, hour, period_start, period_end)
);

CREATE INDEX idx_hourly_distribution_patient ON hourly_usage_distribution(patient_id, period_start, period_end);

-- Tabela de distribuição semanal (pré-agregado)
CREATE TABLE weekly_usage_distribution (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id),
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    average_hours DECIMAL(5,2) NOT NULL,
    occurrence_count INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(patient_id, day_of_week, period_start, period_end)
);

CREATE INDEX idx_weekly_distribution_patient ON weekly_usage_distribution(patient_id, period_start, period_end);
```

### Cache Keys Structure

```go
const (
    // Cache key patterns
    CacheKeyPatientMetrics        = "analytics:patient:%s:metrics:%s:%s"        // patientID, startDate, endDate
    CacheKeyPatientCompliance     = "analytics:patient:%s:compliance:%s:%s"     // patientID, startDate, endDate
    CacheKeyPatientUsagePatterns  = "analytics:patient:%s:patterns:%s:%s"       // patientID, startDate, endDate
    CacheKeyInstitutionDashboard  = "analytics:institution:dashboard:%s:%s"     // startDate, endDate
    CacheKeyInstitutionAverage    = "analytics:institution:avg:%s:%s:%d"        // startDate, endDate, prescribedHours
    
    // Cache TTL
    CacheTTLMetrics      = 5 * time.Minute
    CacheTTLDashboard    = 5 * time.Minute
    CacheTTLInstitution  = 10 * time.Minute
)
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Compliance Calculation Formula

*For any* usage hours and prescribed hours (where prescribed > 0), the compliance percentage should equal (usage_hours / prescribed_hours) * 100

**Validates: Requirements 1.2**

### Property 2: Compliance Color Coding

*For any* compliance value, the color assignment should be: red if compliance < 70, yellow if 70 ≤ compliance < 90, green if compliance ≥ 90

**Validates: Requirements 1.4, 1.5, 1.6**

### Property 3: Date Range Validation

*For any* date range input, if start_date > end_date, the system should reject the input and display an error message

**Validates: Requirements 2.5**

### Property 4: Average Daily Usage Calculation

*For any* set of usage sessions, the average daily usage should equal the sum of all session durations divided by the number of unique days in the period

**Validates: Requirements 3.1**

### Property 5: Session Count Accuracy

*For any* period and patient, the total session count should equal the number of distinct usage_sessions records in that period

**Validates: Requirements 3.2**

### Property 6: Average Session Duration

*For any* set of sessions, the average session duration should equal the sum of all session durations divided by the number of sessions

**Validates: Requirements 3.3**

### Property 7: Compliance Streak Calculation

*For any* sequence of daily compliance values, the current streak should equal the number of consecutive days from today backwards where compliance ≥ 90%

**Validates: Requirements 3.5**

### Property 8: Hourly Distribution Aggregation

*For any* set of usage sessions, the total minutes for each hour should equal the sum of all session minutes that overlap with that hour

**Validates: Requirements 4.2**

### Property 9: Top Hours Highlighting

*For any* hourly distribution data, exactly the 3 hours with the highest usage should be highlighted (or fewer if there are ties or less than 3 hours with data)

**Validates: Requirements 4.4**

### Property 10: Weekly Distribution Calculation

*For any* set of usage sessions, the average hours for each day of week should equal the sum of hours for that day divided by the number of occurrences of that day in the period

**Validates: Requirements 5.2**

### Property 11: Day of Week Ordering

*For any* weekly distribution display, days should be ordered Monday (1) through Sunday (7)

**Validates: Requirements 5.4**

### Property 12: PDF Content Completeness

*For any* generated PDF report, it must contain all required sections: header with logo, patient demographics, executive summary, compliance chart, daily usage table, and footer with page numbers

**Validates: Requirements 6.2, 6.3, 6.4, 6.5, 6.6, 6.7**

### Property 13: Excel Sheet Structure

*For any* generated Excel file, it must contain exactly 4 sheets named "Resumo", "Uso Diário", "Sessões", and "Telemetria"

**Validates: Requirements 7.2, 7.3, 7.4, 7.5**

### Property 14: Excel Date Formatting

*For any* date value in the Excel export, it should be formatted as DD/MM/YYYY HH:MM:SS

**Validates: Requirements 7.6**

### Property 15: Excel Conditional Formatting

*For any* compliance cell in Excel, the background color should be green if value > 90, yellow if 70-90, red if < 70

**Validates: Requirements 7.7**

### Property 16: Institution Dashboard Patient Count

*For any* institution dashboard request, the total active patients should equal the count of patients with status='active' and is_active=true

**Validates: Requirements 8.1**

### Property 17: Institution Average Compliance

*For any* set of active patients, the institution average compliance should equal the sum of all patient compliance values divided by the number of patients

**Validates: Requirements 8.2**

### Property 18: Device Status Categorization

*For any* set of devices, each device should be counted in exactly one category: online, offline, or maintenance

**Validates: Requirements 8.3**

### Property 19: Top/Bottom Patient Lists

*For any* institution dashboard, the lowest compliance list should contain the 10 patients with the smallest compliance values (or fewer if less than 10 patients exist), and similarly for highest compliance

**Validates: Requirements 8.4, 8.5**

### Property 20: Compliance Distribution Bucketing

*For any* patient, they should be counted in exactly one compliance bucket: <50%, 50-70%, 70-90%, or >90%

**Validates: Requirements 8.6**

### Property 21: Timeline Event Ordering

*For any* timeline display, events should be sorted by timestamp in descending order (most recent first)

**Validates: Requirements 9.6**

### Property 22: Inactivity Period Detection

*For any* sequence of usage sessions, if the gap between consecutive sessions exceeds 48 hours, an inactivity marker should be created

**Validates: Requirements 9.4**

### Property 23: Sensor Anomaly Detection

*For any* sensor reading, if the value is outside the defined normal range for that sensor type, it should be flagged as anomalous

**Validates: Requirements 10.5**

### Property 24: Cache Invalidation on Data Insert

*For any* new telemetry data insertion for a patient, all cache entries related to that patient should be invalidated

**Validates: Requirements 11.4**

### Property 25: Cache Hit Before Database Query

*For any* analytics request, the system should check Redis cache before querying PostgreSQL

**Validates: Requirements 11.3**

### Property 26: Response Time Performance

*For any* dashboard load request with period ≤ 1 year, the response time should be < 2 seconds

**Validates: Requirements 11.5**

### Property 27: Institution Average Filtering

*For any* institution average calculation, only patients with prescribed hours within ±2 hours of the target patient should be included

**Validates: Requirements 12.2**

### Property 28: Comparison Indicator

*For any* patient compliance compared to institution average, the indicator should show "above" if patient > average, "below" if patient < average, "equal" if patient = average

**Validates: Requirements 12.3**

## Error Handling

### Error Types

```go
type AnalyticsError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details string `json:"details,omitempty"`
}

const (
    ErrInvalidDateRange      = "INVALID_DATE_RANGE"
    ErrInsufficientData      = "INSUFFICIENT_DATA"
    ErrPatientNotFound       = "PATIENT_NOT_FOUND"
    ErrCacheError            = "CACHE_ERROR"
    ErrDatabaseError         = "DATABASE_ERROR"
    ErrReportGenerationError = "REPORT_GENERATION_ERROR"
    ErrExportError           = "EXPORT_ERROR"
)
```

### Error Handling Strategy

1. **Invalid Input**: Return 400 Bad Request with descriptive error message
2. **Not Found**: Return 404 Not Found when patient/data doesn't exist
3. **Insufficient Data**: Return 200 OK with empty arrays and appropriate messages
4. **Cache Failures**: Log error, fallback to database query
5. **Database Errors**: Return 500 Internal Server Error, log details
6. **Report Generation Failures**: Return 500, provide retry mechanism

## Testing Strategy

### Unit Testing

**Backend (Go):**
- Test compliance calculation functions with various inputs
- Test date range validation logic
- Test aggregation functions
- Test cache key generation
- Test error handling paths

**Frontend (TypeScript/Svelte):**
- Test chart component rendering with mock data
- Test date picker validation
- Test export button click handlers
- Test tooltip display logic
- Test color coding functions

### Property-Based Testing

We will use **Rapid** (Go property-based testing library) for backend and **fast-check** (TypeScript) for frontend.

**Configuration:**
- Minimum 100 iterations per property test
- Use shrinking to find minimal failing cases
- Generate realistic test data within valid ranges

**Key Properties to Test:**
- Compliance calculation formula (Property 1)
- Color coding rules (Property 2)
- Date validation (Property 3)
- All aggregation calculations (Properties 4-11)
- Cache behavior (Properties 24-25)

### Integration Testing

- Test full API endpoints with real database
- Test cache integration with Redis
- Test PDF generation end-to-end
- Test Excel generation end-to-end
- Test concurrent requests handling

### Performance Testing

- Load test with 100 concurrent users
- Test response times with 1 year of data
- Test cache hit rates
- Test database query performance
- Test report generation time

## Performance Optimization

### Database Optimization

1. **Indexes**: Create appropriate indexes on frequently queried columns
2. **Aggregation Tables**: Pre-calculate daily/hourly/weekly aggregations
3. **Query Optimization**: Use EXPLAIN ANALYZE to optimize slow queries
4. **Connection Pooling**: Configure appropriate pool size

### Caching Strategy

1. **Cache Warming**: Pre-populate cache for frequently accessed data
2. **Cache Invalidation**: Invalidate on data updates
3. **TTL Configuration**: Balance freshness vs performance
4. **Cache Aside Pattern**: Check cache first, populate on miss

### Frontend Optimization

1. **Lazy Loading**: Load charts only when visible
2. **Data Pagination**: Limit initial data load
3. **Debouncing**: Debounce filter changes
4. **Memoization**: Cache computed values in components

## Security Considerations

1. **Authorization**: Verify user has access to requested patient data
2. **Input Validation**: Sanitize all user inputs
3. **SQL Injection Prevention**: Use parameterized queries
4. **Rate Limiting**: Limit export requests per user
5. **File Access Control**: Secure generated report files
6. **LGPD Compliance**: Ensure exported data follows consent rules

## Deployment Considerations

### Environment Variables

```bash
# Analytics Configuration
ANALYTICS_CACHE_TTL=300
ANALYTICS_MAX_PERIOD_DAYS=365
ANALYTICS_REPORT_STORAGE_PATH=/var/orthotrack/reports
ANALYTICS_MAX_EXPORT_SIZE_MB=50

# Performance
ANALYTICS_DB_POOL_SIZE=20
ANALYTICS_CACHE_POOL_SIZE=10
ANALYTICS_WORKER_THREADS=4
```

### Monitoring

- Track API response times
- Monitor cache hit rates
- Alert on slow queries (>1s)
- Track report generation failures
- Monitor disk space for reports

### Scalability

- Horizontal scaling of API servers
- Read replicas for analytics queries
- Separate Redis instance for analytics cache
- Background workers for report generation
- CDN for serving generated reports

---

**Document Version**: 1.0  
**Last Updated**: 2024-12-09  
**Next Review**: After implementation phase 1
