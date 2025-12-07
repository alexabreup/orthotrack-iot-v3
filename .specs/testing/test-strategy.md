# Testing Strategy - OrthoTrack IoT v3

## 🧪 Estratégia Geral de Testes

### Objetivos
- Garantir qualidade e confiabilidade do sistema
- Detectar problemas antes da produção
- Facilitar refatoração e manutenção
- Validar requisitos funcionais e não-funcionais
- Assegurar segurança e privacidade dos dados

### Pirâmide de Testes
```
                    🔺 E2E Tests (5%)
                   📊 Integration Tests (25%)
              🧩 Unit Tests (70%)
```

### Cobertura de Código Alvo
- **Backend**: Mínimo 80%, meta 90%
- **Frontend**: Mínimo 70%, meta 85%
- **Android**: Mínimo 75%, meta 85%
- **ESP32**: Mínimo 60%, meta 75%

---

## 🔧 Backend Testing (GoLang)

### Unit Tests

#### Framework e Tools
- **Testing Framework**: Go standard testing package
- **Mocking**: Testify/mock, GoMock
- **Coverage**: go test -cover
- **CI Integration**: GitHub Actions

#### Estrutura de Testes
```go
// Exemplo de estrutura de teste
func TestPatientService_CreatePatient(t *testing.T) {
    // Setup
    mockRepo := &mocks.PatientRepository{}
    service := NewPatientService(mockRepo, logger)
    
    testCases := []struct {
        name        string
        input       CreatePatientRequest
        setupMock   func(*mocks.PatientRepository)
        expected    *Patient
        expectError bool
    }{
        {
            name: "valid patient creation",
            input: CreatePatientRequest{
                Name:  "João Silva",
                Email: "joao@test.com",
                CPF:   "123.456.789-00",
            },
            setupMock: func(mock *mocks.PatientRepository) {
                mock.On("Create", mock.Anything).Return(&Patient{
                    ID:   1,
                    Name: "João Silva",
                }, nil)
            },
            expected: &Patient{ID: 1, Name: "João Silva"},
            expectError: false,
        },
        {
            name: "invalid email",
            input: CreatePatientRequest{
                Name:  "João Silva",
                Email: "invalid-email",
                CPF:   "123.456.789-00",
            },
            setupMock:   func(mock *mocks.PatientRepository) {},
            expected:    nil,
            expectError: true,
        },
    }
    
    for _, tc := range testCases {
        t.Run(tc.name, func(t *testing.T) {
            // Given
            tc.setupMock(mockRepo)
            
            // When
            result, err := service.CreatePatient(tc.input)
            
            // Then
            if tc.expectError {
                assert.Error(t, err)
                assert.Nil(t, result)
            } else {
                assert.NoError(t, err)
                assert.Equal(t, tc.expected.Name, result.Name)
            }
            
            mockRepo.AssertExpectations(t)
        })
    }
}
```

#### Casos de Teste Obrigatórios
- **Models**: Validação de campos, relacionamentos
- **Services**: Lógica de negócio, cenários de erro
- **Repositories**: CRUD operations, queries complexas
- **Handlers**: Request/response, validation, auth
- **Middleware**: Authentication, logging, rate limiting
- **Utils**: Funções auxiliares, formatação

### Integration Tests

#### Database Tests
```go
func TestPatientRepository_Integration(t *testing.T) {
    // Setup test database
    db := setupTestDB(t)
    defer teardownTestDB(t, db)
    
    repo := NewPatientRepository(db)
    
    t.Run("create and retrieve patient", func(t *testing.T) {
        // Given
        patient := &Patient{
            Name:  "Test Patient",
            Email: "test@example.com",
            CPF:   "123.456.789-00",
        }
        
        // When
        created, err := repo.Create(patient)
        assert.NoError(t, err)
        
        retrieved, err := repo.GetByID(created.ID)
        
        // Then
        assert.NoError(t, err)
        assert.Equal(t, patient.Name, retrieved.Name)
    })
}
```

#### API Tests
```go
func TestPatientAPI_Integration(t *testing.T) {
    // Setup test server
    server := setupTestServer(t)
    defer server.Close()
    
    client := &http.Client{Timeout: 10 * time.Second}
    
    t.Run("POST /patients", func(t *testing.T) {
        // Given
        payload := `{
            "name": "Test Patient",
            "email": "test@example.com",
            "cpf": "123.456.789-00"
        }`
        
        // When
        resp, err := client.Post(
            server.URL+"/api/v1/patients",
            "application/json",
            strings.NewReader(payload),
        )
        
        // Then
        assert.NoError(t, err)
        assert.Equal(t, http.StatusCreated, resp.StatusCode)
        
        var patient Patient
        json.NewDecoder(resp.Body).Decode(&patient)
        assert.NotZero(t, patient.ID)
        assert.Equal(t, "Test Patient", patient.Name)
    })
}
```

### Performance Tests

#### Load Testing com Go
```go
func BenchmarkTelemetryEndpoint(b *testing.B) {
    server := setupTestServer(b)
    defer server.Close()
    
    payload := generateSensorData()
    
    b.ResetTimer()
    b.RunParallel(func(pb *testing.PB) {
        client := &http.Client{}
        for pb.Next() {
            resp, err := client.Post(
                server.URL+"/api/v1/telemetry",
                "application/json",
                bytes.NewReader(payload),
            )
            if err != nil {
                b.Fatal(err)
            }
            resp.Body.Close()
        }
    })
}
```

---

## 🎨 Frontend Testing (SvelteKit)

### Unit Tests

#### Framework e Tools
- **Testing Framework**: Vitest + Testing Library
- **Mocking**: Vitest mocks
- **Coverage**: c8
- **Browser Testing**: Playwright

#### Component Tests
```typescript
// PatientCard.test.ts
import { render, screen, fireEvent } from '@testing-library/svelte';
import { vi } from 'vitest';
import PatientCard from '$lib/components/PatientCard.svelte';
import type { Patient } from '$lib/types/patient';

const mockPatient: Patient = {
  id: 1,
  name: 'João Silva',
  external_id: 'AACD001',
  compliance_score: 85,
  status: 'active',
  // ... outros campos
};

describe('PatientCard', () => {
  it('renders patient information correctly', () => {
    render(PatientCard, { patient: mockPatient });
    
    expect(screen.getByText('João Silva')).toBeInTheDocument();
    expect(screen.getByText('AACD001')).toBeInTheDocument();
    expect(screen.getByText('85%')).toBeInTheDocument();
  });

  it('calls onEdit when edit button is clicked', async () => {
    const handleEdit = vi.fn();
    render(PatientCard, { 
      patient: mockPatient,
      onEdit: handleEdit 
    });
    
    const editButton = screen.getByRole('button', { name: /editar/i });
    await fireEvent.click(editButton);
    
    expect(handleEdit).toHaveBeenCalledWith(mockPatient);
  });

  it('shows correct compliance status color', () => {
    const { container } = render(PatientCard, { patient: mockPatient });
    const complianceBar = container.querySelector('[data-testid=compliance-bar]');
    
    expect(complianceBar).toHaveClass('bg-green-500'); // 85% is good
  });
});
```

#### Store Tests
```typescript
// auth.test.ts
import { get } from 'svelte/store';
import { auth } from '$lib/stores/auth';
import { authService } from '$lib/services/auth';
import { vi } from 'vitest';

vi.mock('$lib/services/auth');

describe('Auth Store', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should login successfully', async () => {
    const mockUser = { id: 1, email: 'test@example.com', name: 'Test User' };
    vi.mocked(authService.login).mockResolvedValue({
      user: mockUser,
      token: 'fake-token'
    });

    await auth.login({ email: 'test@example.com', password: 'password' });

    const state = get(auth);
    expect(state.isAuthenticated).toBe(true);
    expect(state.user).toEqual(mockUser);
    expect(state.isLoading).toBe(false);
  });

  it('should handle login failure', async () => {
    vi.mocked(authService.login).mockRejectedValue(new Error('Invalid credentials'));

    await expect(auth.login({ 
      email: 'test@example.com', 
      password: 'wrong' 
    })).rejects.toThrow('Invalid credentials');

    const state = get(auth);
    expect(state.isAuthenticated).toBe(false);
    expect(state.user).toBeNull();
  });
});
```

### Integration Tests

#### API Service Tests
```typescript
// patientService.test.ts
import { patientService } from '$lib/services/patient';
import { setupServer } from 'msw/node';
import { rest } from 'msw';

const server = setupServer(
  rest.get('/api/v1/patients', (req, res, ctx) => {
    return res(ctx.json({
      patients: [
        { id: 1, name: 'João Silva', external_id: 'AACD001' },
        { id: 2, name: 'Maria Santos', external_id: 'AACD002' }
      ],
      total: 2
    }));
  }),

  rest.post('/api/v1/patients', (req, res, ctx) => {
    return res(ctx.status(201), ctx.json({
      id: 3,
      name: 'New Patient',
      external_id: 'AACD003'
    }));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('Patient Service', () => {
  it('should fetch patients list', async () => {
    const result = await patientService.getPatients();
    
    expect(result.patients).toHaveLength(2);
    expect(result.total).toBe(2);
    expect(result.patients[0].name).toBe('João Silva');
  });

  it('should create new patient', async () => {
    const newPatient = {
      name: 'New Patient',
      external_id: 'AACD003',
      email: 'new@example.com'
    };

    const result = await patientService.createPatient(newPatient);
    
    expect(result.id).toBe(3);
    expect(result.name).toBe('New Patient');
  });
});
```

### E2E Tests

#### Playwright Tests
```typescript
// patient-management.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Patient Management', () => {
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto('/auth/login');
    await page.fill('[data-testid=email]', 'admin@orthotrack.com');
    await page.fill('[data-testid=password]', 'password');
    await page.click('[data-testid=login-button]');
    
    // Wait for dashboard
    await expect(page).toHaveURL('/');
  });

  test('should create new patient', async ({ page }) => {
    // Navigate to patients
    await page.click('[data-testid=patients-nav]');
    await expect(page).toHaveURL('/patients');

    // Open create form
    await page.click('[data-testid=new-patient-button]');
    
    // Fill form
    await page.fill('[data-testid=patient-name]', 'João Silva');
    await page.fill('[data-testid=patient-cpf]', '123.456.789-00');
    await page.fill('[data-testid=patient-email]', 'joao@example.com');
    await page.selectOption('[data-testid=institution]', '1');
    
    // Submit form
    await page.click('[data-testid=save-button]');
    
    // Verify success
    await expect(page.locator('[data-testid=success-message]')).toContainText('Paciente criado com sucesso');
    await expect(page.locator('[data-testid=patients-table]')).toContainText('João Silva');
  });

  test('should display real-time device status', async ({ page }) => {
    await page.goto('/devices');
    
    // Mock WebSocket connection
    await page.evaluate(() => {
      const mockWS = {
        send: () => {},
        close: () => {},
        addEventListener: (event: string, handler: Function) => {
          if (event === 'message') {
            // Simulate device status update
            setTimeout(() => {
              handler({
                data: JSON.stringify({
                  type: 'device_status',
                  device_id: 1,
                  status: { battery: 85, online: true }
                })
              });
            }, 1000);
          }
        }
      };
      
      // @ts-ignore
      window.WebSocket = function() { return mockWS; };
    });
    
    // Wait for status update
    await expect(page.locator('[data-testid=device-1-battery]')).toContainText('85%');
    await expect(page.locator('[data-testid=device-1-status]')).toContainText('Online');
  });
});
```

---

## 📱 Android Testing

### Unit Tests

#### Framework e Tools
- **Testing Framework**: JUnit 4/5 + Mockito
- **UI Testing**: Espresso
- **Architecture Testing**: AndroidX Test
- **Coverage**: JaCoCo

#### Repository Tests
```kotlin
@ExtendWith(MockitoExtension::class)
class SensorDataRepositoryTest {
    
    @Mock
    private lateinit var sensorReadingDao: SensorReadingDao
    
    @Mock
    private lateinit var apiService: OrthoTrackApiService
    
    private lateinit var repository: SensorDataRepositoryImpl
    
    @BeforeEach
    fun setup() {
        repository = SensorDataRepositoryImpl(sensorReadingDao, apiService, syncQueueDao, dataProcessor)
    }
    
    @Test
    fun `storeSensorReading should save to database and queue for sync`() = runTest {
        // Given
        val reading = SensorReading(
            braceId = "test-brace",
            timestamp = System.currentTimeMillis(),
            accelX = 1.0f,
            accelY = 2.0f,
            accelZ = 3.0f,
            isWearing = true
        )
        
        // When
        val result = repository.storeSensorReading(reading)
        
        // Then
        assertTrue(result.isSuccess)
        verify(sensorReadingDao).insertReading(any())
        verify(syncQueueDao).insertSyncItem(any())
    }
}
```

#### ViewModel Tests
```kotlin
@ExtendWith(MockitoExtension::class)
class DeviceConnectionViewModelTest {
    
    @Mock
    private lateinit var bleScanner: BleScanner
    
    @Mock
    private lateinit var connectionManager: BleConnectionManager
    
    private lateinit var viewModel: DeviceConnectionViewModel
    
    @BeforeEach
    fun setup() {
        viewModel = DeviceConnectionViewModel(bleScanner, connectionManager)
    }
    
    @Test
    fun `startScanning should emit scanning state`() = runTest {
        // Given
        val devicesFlow = flowOf(listOf(mockBluetoothDevice))
        whenever(bleScanner.startScan()).thenReturn(devicesFlow)
        
        // When
        viewModel.startScanning()
        
        // Then
        val uiStates = mutableListOf<DeviceConnectionUiState>()
        val job = launch {
            viewModel.uiState.collect { uiStates.add(it) }
        }
        
        advanceTimeBy(1000)
        
        assertTrue(uiStates.any { it is DeviceConnectionUiState.Scanning })
        assertTrue(uiStates.any { it is DeviceConnectionUiState.Success })
        
        job.cancel()
    }
}
```

### Integration Tests

#### Database Tests
```kotlin
@RunWith(AndroidJUnit4::class)
class SensorReadingDaoTest {
    
    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()
    
    private lateinit var database: OrthoTrackDatabase
    private lateinit var sensorReadingDao: SensorReadingDao
    
    @Before
    fun createDb() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        database = Room.inMemoryDatabaseBuilder(
            context, 
            OrthoTrackDatabase::class.java
        ).allowMainThreadQueries().build()
        
        sensorReadingDao = database.sensorReadingDao()
    }
    
    @After
    fun closeDb() {
        database.close()
    }
    
    @Test
    fun insertAndGetSensorReading() = runTest {
        // Given
        val reading = SensorReadingEntity(
            braceId = "test-brace",
            timestamp = System.currentTimeMillis(),
            accelX = 1.0f,
            accelY = 2.0f,
            accelZ = 3.0f,
            isWearing = true,
            isSynced = false
        )
        
        // When
        val id = sensorReadingDao.insertReading(reading)
        val retrieved = sensorReadingDao.getReadingById(id)
        
        // Then
        assertNotNull(retrieved)
        assertEquals("test-brace", retrieved?.braceId)
        assertEquals(1.0f, retrieved?.accelX)
        assertFalse(retrieved?.isSynced ?: true)
    }
    
    @Test
    fun getReadingsByBraceId() = runTest {
        // Given
        val readings = listOf(
            SensorReadingEntity(braceId = "brace1", timestamp = 1000, accelX = 1.0f),
            SensorReadingEntity(braceId = "brace1", timestamp = 2000, accelX = 2.0f),
            SensorReadingEntity(braceId = "brace2", timestamp = 1500, accelX = 1.5f)
        )
        
        readings.forEach { sensorReadingDao.insertReading(it) }
        
        // When
        val brace1Readings = sensorReadingDao.getReadingsByBraceId("brace1", 10, 0)
            .first()
        
        // Then
        assertEquals(2, brace1Readings.size)
        assertEquals(2000, brace1Readings[0].timestamp) // Most recent first
    }
}
```

### UI Tests

#### Espresso Tests
```kotlin
@RunWith(AndroidJUnit4::class)
class DashboardActivityTest {
    
    @get:Rule
    val activityRule = ActivityScenarioRule(MainActivity::class.java)
    
    @Before
    fun setup() {
        // Mock authentication
        val intent = Intent(ApplicationProvider.getApplicationContext(), MainActivity::class.java)
        intent.putExtra("authenticated", true)
        activityRule.scenario.onActivity { activity ->
            activity.intent = intent
        }
    }
    
    @Test
    fun displaysDashboardStats() {
        // Given - Mock data is loaded
        
        // When - Dashboard is displayed
        onView(withId(R.id.dashboard_fragment))
            .check(matches(isDisplayed()))
        
        // Then - Stats are visible
        onView(withId(R.id.connected_devices_stat))
            .check(matches(isDisplayed()))
        
        onView(withId(R.id.active_sessions_stat))
            .check(matches(isDisplayed()))
        
        onView(withId(R.id.pending_alerts_stat))
            .check(matches(isDisplayed()))
    }
    
    @Test
    fun navigatesToDeviceScreen() {
        // When
        onView(withId(R.id.nav_devices))
            .perform(click())
        
        // Then
        onView(withId(R.id.device_connection_fragment))
            .check(matches(isDisplayed()))
        
        onView(withText("Dispositivos Disponíveis"))
            .check(matches(isDisplayed()))
    }
    
    @Test
    fun scanForDevices() {
        // Navigate to devices
        onView(withId(R.id.nav_devices)).perform(click())
        
        // When
        onView(withId(R.id.scan_button))
            .perform(click())
        
        // Then
        onView(withText("Buscando..."))
            .check(matches(isDisplayed()))
        
        // Wait for scan completion
        onView(isRoot()).perform(waitFor(3000))
        
        onView(withId(R.id.devices_recycler_view))
            .check(matches(isDisplayed()))
    }
}
```

---

## ⚡ ESP32 Testing

### Unit Tests

#### Framework e Tools
- **Testing Framework**: Unity + PlatformIO
- **Mocking**: CMock (se necessário)
- **Coverage**: gcov (limitado no embedded)

#### Sensor Tests
```cpp
// test_mpu6050.cpp
#include <unity.h>
#include "sensors/mpu6050.h"

MPU6050 sensor;

void setUp(void) {
    // Setup I2C mock or actual hardware
    sensor.initialize();
}

void tearDown(void) {
    // Cleanup
}

void test_mpu6050_initialization() {
    // Test if sensor initializes correctly
    TEST_ASSERT_TRUE(sensor.isInitialized());
}

void test_mpu6050_read_data() {
    MPU6050::AccelGyroData data;
    esp_err_t result = sensor.readData(data);
    
    TEST_ASSERT_EQUAL(ESP_OK, result);
    TEST_ASSERT_NOT_EQUAL(0, data.timestamp);
    
    // Basic sanity checks for accelerometer (assuming device is level)
    TEST_ASSERT_FLOAT_WITHIN(0.2, 0.0, data.accelX);
    TEST_ASSERT_FLOAT_WITHIN(0.2, 0.0, data.accelY);
    TEST_ASSERT_FLOAT_WITHIN(0.2, 1.0, data.accelZ);  // Gravity
}

void test_mpu6050_calibration() {
    esp_err_t result = sensor.calibrate();
    
    TEST_ASSERT_EQUAL(ESP_OK, result);
    
    // After calibration, readings should be more accurate
    MPU6050::AccelGyroData data;
    sensor.readData(data);
    
    // Gyro should be near zero when stationary
    TEST_ASSERT_FLOAT_WITHIN(1.0, 0.0, data.gyroX);
    TEST_ASSERT_FLOAT_WITHIN(1.0, 0.0, data.gyroY);
    TEST_ASSERT_FLOAT_WITHIN(1.0, 0.0, data.gyroZ);
}

int main() {
    UNITY_BEGIN();
    
    RUN_TEST(test_mpu6050_initialization);
    RUN_TEST(test_mpu6050_read_data);
    RUN_TEST(test_mpu6050_calibration);
    
    return UNITY_END();
}
```

#### BLE Tests
```cpp
// test_ble_protocol.cpp
#include <unity.h>
#include "ble/ble_protocol.h"

void test_sensor_packet_serialization() {
    OrthoTrackProtocol::SensorDataPacket packet;
    packet.timestamp = 1234567890;
    packet.accelX = 1.23f;
    packet.accelY = 2.34f;
    packet.accelZ = 3.45f;
    packet.temperature = 25.5f;
    packet.batteryVoltage = 3.7f;
    
    uint8_t buffer[64];
    size_t size = packet.serialize(buffer, sizeof(buffer));
    
    TEST_ASSERT_GREATER_THAN(0, size);
    TEST_ASSERT_LESS_OR_EQUAL(sizeof(buffer), size);
    
    // Test deserialization
    OrthoTrackProtocol::SensorDataPacket unpacked;
    bool success = unpacked.deserialize(buffer, size);
    
    TEST_ASSERT_TRUE(success);
    TEST_ASSERT_EQUAL(packet.timestamp, unpacked.timestamp);
    TEST_ASSERT_FLOAT_WITHIN(0.001, packet.accelX, unpacked.accelX);
    TEST_ASSERT_FLOAT_WITHIN(0.001, packet.temperature, unpacked.temperature);
}

void test_command_processing() {
    uint8_t startCommand[] = {CMD_START_SESSION, 0x01};  // Enable session
    uint8_t stopCommand[] = {CMD_STOP_SESSION};
    
    // Test start command
    CommandResult result = processCommand(startCommand, sizeof(startCommand));
    TEST_ASSERT_EQUAL(CMD_SUCCESS, result.status);
    TEST_ASSERT_TRUE(isSessionActive());
    
    // Test stop command  
    result = processCommand(stopCommand, sizeof(stopCommand));
    TEST_ASSERT_EQUAL(CMD_SUCCESS, result.status);
    TEST_ASSERT_FALSE(isSessionActive());
}
```

### Integration Tests

#### Hardware-in-the-Loop Tests
```cpp
// test_sensor_integration.cpp
#include <unity.h>
#include "system/sensor_manager.h"
#include "ble/ble_server.h"

SensorManager sensorManager;
BLEServer bleServer;

void test_complete_data_flow() {
    // Initialize all components
    TEST_ASSERT_EQUAL(ESP_OK, sensorManager.initialize());
    TEST_ASSERT_EQUAL(ESP_OK, bleServer.initialize());
    
    // Start data collection
    sensorManager.startCollection();
    
    // Wait for some samples
    vTaskDelay(pdMS_TO_TICKS(1000));
    
    // Check if data is being collected
    uint32_t sampleCount = sensorManager.getSampleCount();
    TEST_ASSERT_GREATER_THAN(10, sampleCount);  // At least 10 samples in 1 second
    
    // Check if data is being transmitted
    if (bleServer.isConnected()) {
        uint32_t transmitCount = bleServer.getTransmitCount();
        TEST_ASSERT_GREATER_THAN(0, transmitCount);
    }
    
    sensorManager.stopCollection();
}

void test_power_management() {
    PowerManager powerManager;
    TEST_ASSERT_EQUAL(ESP_OK, powerManager.initialize());
    
    // Test sleep mode transition
    powerManager.updatePowerMode(false, 50);  // Not wearing, 50% battery
    vTaskDelay(pdMS_TO_TICKS(100));
    
    // Should be in low power mode
    TEST_ASSERT_EQUAL(PowerMode::LOW_POWER, powerManager.getCurrentMode());
    
    // Test wake up
    powerManager.updatePowerMode(true, 50);   // Start wearing
    vTaskDelay(pdMS_TO_TICKS(100));
    
    // Should be back to active mode
    TEST_ASSERT_EQUAL(PowerMode::ACTIVE, powerManager.getCurrentMode());
}
```

---

## 🔄 CI/CD Testing

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: orthotrack_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:6
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'
    
    - name: Install dependencies
      run: |
        cd backend
        go mod download
    
    - name: Run tests
      run: |
        cd backend
        go test -v -race -coverprofile=coverage.out ./...
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./backend/coverage.out

  frontend-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: frontend/package-lock.json
    
    - name: Install dependencies
      run: |
        cd frontend
        npm ci
    
    - name: Run unit tests
      run: |
        cd frontend
        npm run test:unit
    
    - name: Run E2E tests
      run: |
        cd frontend
        npm run build
        npm run test:e2e
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./frontend/coverage/lcov.info

  android-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Setup Android SDK
      uses: android-actions/setup-android@v3
    
    - name: Cache Gradle packages
      uses: actions/cache@v3
      with:
        path: |
          ~/.gradle/caches
          ~/.gradle/wrapper
        key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
    
    - name: Run unit tests
      run: |
        cd android-edge-node
        ./gradlew testDebugUnitTest
    
    - name: Run instrumented tests
      uses: reactivecircus/android-emulator-runner@v2
      with:
        api-level: 29
        script: |
          cd android-edge-node
          ./gradlew connectedDebugAndroidTest

  esp32-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install PlatformIO
      run: |
        pip install platformio
    
    - name: Run tests
      run: |
        cd esp32-firmware
        pio test -e native
```

---

## 📊 Test Metrics and Reporting

### Coverage Reports

#### Backend Coverage
```bash
# Generate coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html

# Coverage targets by package
internal/models/     - 95%
internal/services/   - 90%
internal/handlers/   - 85%
internal/middleware/ - 80%
```

#### Frontend Coverage
```bash
# Generate coverage report
npm run test:coverage

# Coverage targets by directory
src/lib/components/  - 85%
src/lib/services/    - 90%
src/lib/stores/      - 85%
src/routes/          - 70%
```

### Quality Gates

#### Automated Quality Checks
```yaml
# quality-gates.yml
coverage:
  minimum: 80%
  target: 90%

performance:
  api_response_time: 200ms
  page_load_time: 2s
  battery_life: 72h

security:
  vulnerability_scan: required
  dependency_check: required
  code_analysis: required

accessibility:
  wcag_level: AA
  lighthouse_score: 90
```

---

## 🚨 Test Environment Management

### Test Data Management

#### Database Seeds
```sql
-- test-seeds.sql
INSERT INTO institutions (id, name, code) VALUES
(1, 'AACD São Paulo', 'AACD-SP'),
(2, 'AACD Rio de Janeiro', 'AACD-RJ');

INSERT INTO patients (id, external_id, name, institution_id) VALUES
(1, 'AACD001', 'João Silva', 1),
(2, 'AACD002', 'Maria Santos', 1),
(3, 'AACD003', 'Pedro Costa', 2);

INSERT INTO braces (id, serial_number, patient_id, status) VALUES
(1, 'ESP32-001', 1, 'active'),
(2, 'ESP32-002', 2, 'active'),
(3, 'ESP32-003', 3, 'maintenance');
```

#### Mock Data Generation
```typescript
// test-utils/mockData.ts
export function generateSensorReading(overrides?: Partial<SensorReading>): SensorReading {
  return {
    id: faker.number.int(),
    braceId: faker.string.uuid(),
    timestamp: Date.now(),
    accelX: faker.number.float({ min: -2, max: 2 }),
    accelY: faker.number.float({ min: -2, max: 2 }),
    accelZ: faker.number.float({ min: -2, max: 2 }),
    temperature: faker.number.float({ min: 20, max: 40 }),
    isWearing: faker.datatype.boolean(),
    ...overrides
  };
}

export function generatePatient(overrides?: Partial<Patient>): Patient {
  return {
    id: faker.number.int(),
    name: faker.person.fullName(),
    external_id: `AACD${faker.number.int({ min: 100, max: 999 })}`,
    email: faker.internet.email(),
    cpf: faker.helpers.replaceSymbols('###.###.###-##'),
    compliance_score: faker.number.int({ min: 60, max: 100 }),
    status: faker.helpers.arrayElement(['active', 'inactive', 'completed']),
    ...overrides
  };
}
```

### Environment Configuration

#### Test Environment Variables
```bash
# .env.test
NODE_ENV=test
DATABASE_URL=postgres://test:test@localhost:5432/orthotrack_test
REDIS_URL=redis://localhost:6379/1
JWT_SECRET=test-secret-key
API_BASE_URL=http://localhost:8080/api/v1

# Mock external services
OPENAI_API_KEY=mock-key
DEEPSEEK_API_KEY=mock-key
```

---

**Estratégia de Testes Completa - OrthoTrack IoT v3**  
**Versão**: 1.0  
**Última Atualização**: 2024-12-03