# ESP32 Firmware Technical Specifications

## 🔧 Hardware Architecture

### ESP32 Board Configuration
- **MCU**: ESP32-WROOM-32E (or ESP32-S3)
- **Flash Memory**: 4MB minimum (8MB recommended)
- **SRAM**: 520KB
- **Bluetooth**: BLE 5.0 + BR/EDR
- **WiFi**: 802.11 b/g/n (2.4 GHz)
- **ADC**: 12-bit, up to 18 channels
- **Power**: 3.3V operation, deep sleep support

### Sensor Configuration
```cpp
// Pin definitions
#define MPU6050_SDA_PIN     21
#define MPU6050_SCL_PIN     22
#define DHT22_DATA_PIN      18
#define FSR_PINS           {34, 35, 36, 39}  // ADC pins
#define BATTERY_ADC_PIN     32
#define STATUS_LED_PIN      2
#define BUZZER_PIN          5

// I2C Configuration
#define I2C_FREQ_HZ         400000
#define MPU6050_ADDR        0x68

// ADC Configuration
#define ADC_RESOLUTION      4096    // 12-bit
#define ADC_VREF           3.3      // Reference voltage
```

### Power Management
```cpp
// Battery monitoring
#define BATTERY_MIN_VOLTAGE    3.0   // Shutdown voltage
#define BATTERY_LOW_VOLTAGE    3.3   // Low battery warning
#define BATTERY_FULL_VOLTAGE   4.2   // Full charge voltage

// Sleep modes
#define LIGHT_SLEEP_DURATION   100   // ms - between readings
#define DEEP_SLEEP_DURATION    30    // seconds - when inactive
#define WAKE_UP_THRESHOLD      0.5   // g - acceleration threshold
```

---

## 🏗️ Firmware Architecture

### Project Structure
```
esp32-firmware/
├── src/
│   ├── main.cpp              # Entry point
│   ├── config/
│   │   ├── pins.h            # Pin definitions
│   │   ├── constants.h       # System constants
│   │   └── version.h         # Firmware version
│   ├── sensors/
│   │   ├── mpu6050.cpp/h     # Accelerometer/Gyroscope
│   │   ├── dht22.cpp/h       # Temperature/Humidity
│   │   ├── fsr.cpp/h         # Force Sensitive Resistors
│   │   ├── battery.cpp/h     # Battery monitoring
│   │   └── sensor_fusion.cpp/h # Sensor data fusion
│   ├── ble/
│   │   ├── ble_server.cpp/h  # BLE GATT server
│   │   ├── ble_callbacks.cpp/h # BLE event handlers
│   │   └── ble_protocol.cpp/h # Communication protocol
│   ├── ai/
│   │   ├── tinyml.cpp/h      # TensorFlow Lite Micro
│   │   ├── movement_detector.cpp/h # Movement classification
│   │   └── posture_analyzer.cpp/h # Posture analysis
│   ├── power/
│   │   ├── power_manager.cpp/h # Power management
│   │   ├── sleep_controller.cpp/h # Sleep modes
│   │   └── battery_monitor.cpp/h # Battery status
│   ├── storage/
│   │   ├── nvs_manager.cpp/h # Non-volatile storage
│   │   ├── calibration.cpp/h # Sensor calibration data
│   │   └── config_storage.cpp/h # Configuration persistence
│   ├── utils/
│   │   ├── logger.cpp/h      # Logging utilities
│   │   ├── math_utils.cpp/h  # Mathematical functions
│   │   └── time_utils.cpp/h  # Time management
│   └── tasks/
│       ├── sensor_task.cpp/h # Sensor reading task
│       ├── ble_task.cpp/h    # BLE communication task
│       ├── ai_task.cpp/h     # AI processing task
│       └── watchdog_task.cpp/h # System monitoring
├── lib/                      # External libraries
├── include/                  # Header files
├── test/                     # Unit tests
├── data/                     # AI models and assets
├── platformio.ini            # PlatformIO configuration
└── CMakeLists.txt           # Build configuration
```

### Core Task Architecture
```cpp
// tasks/task_manager.cpp
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

// Task priorities
#define SENSOR_TASK_PRIORITY      3
#define BLE_TASK_PRIORITY         2
#define AI_TASK_PRIORITY          1
#define WATCHDOG_TASK_PRIORITY    4

// Task stack sizes
#define SENSOR_TASK_STACK_SIZE    4096
#define BLE_TASK_STACK_SIZE       8192
#define AI_TASK_STACK_SIZE        16384
#define WATCHDOG_TASK_STACK_SIZE  2048

// Inter-task communication
extern QueueHandle_t sensorDataQueue;
extern QueueHandle_t bleDataQueue;
extern QueueHandle_t aiResultQueue;

class TaskManager {
public:
    static void initializeTasks() {
        // Create queues
        sensorDataQueue = xQueueCreate(50, sizeof(SensorData));
        bleDataQueue = xQueueCreate(20, sizeof(BLEMessage));
        aiResultQueue = xQueueCreate(10, sizeof(AIResult));
        
        // Create tasks
        xTaskCreate(
            sensorTaskHandler,
            "sensor_task",
            SENSOR_TASK_STACK_SIZE,
            nullptr,
            SENSOR_TASK_PRIORITY,
            &sensorTaskHandle
        );
        
        xTaskCreate(
            bleTaskHandler,
            "ble_task",
            BLE_TASK_STACK_SIZE,
            nullptr,
            BLE_TASK_PRIORITY,
            &bleTaskHandle
        );
        
        xTaskCreate(
            aiTaskHandler,
            "ai_task",
            AI_TASK_STACK_SIZE,
            nullptr,
            AI_TASK_PRIORITY,
            &aiTaskHandle
        );
        
        xTaskCreate(
            watchdogTaskHandler,
            "watchdog_task",
            WATCHDOG_TASK_STACK_SIZE,
            nullptr,
            WATCHDOG_TASK_PRIORITY,
            &watchdogTaskHandle
        );
    }
    
private:
    static TaskHandle_t sensorTaskHandle;
    static TaskHandle_t bleTaskHandle;
    static TaskHandle_t aiTaskHandle;
    static TaskHandle_t watchdogTaskHandle;
};
```

---

## 📡 Sensor Implementation

### MPU6050 Accelerometer/Gyroscope
```cpp
// sensors/mpu6050.cpp
#include "mpu6050.h"
#include "driver/i2c.h"
#include "esp_log.h"

class MPU6050 {
private:
    static constexpr char TAG[] = "MPU6050";
    
    // Register addresses
    static constexpr uint8_t PWR_MGMT_1 = 0x6B;
    static constexpr uint8_t ACCEL_XOUT_H = 0x3B;
    static constexpr uint8_t GYRO_XOUT_H = 0x43;
    static constexpr uint8_t CONFIG = 0x1A;
    static constexpr uint8_t ACCEL_CONFIG = 0x1C;
    static constexpr uint8_t GYRO_CONFIG = 0x1B;
    
    // Scale factors
    static constexpr float ACCEL_SCALE = 16384.0f;  // ±2g
    static constexpr float GYRO_SCALE = 131.0f;     // ±250°/s
    
    bool initialized = false;
    AccelGyroData calibrationOffset = {0};
    
public:
    struct AccelGyroData {
        float accelX, accelY, accelZ;  // in g
        float gyroX, gyroY, gyroZ;     // in °/s
        uint32_t timestamp;            // in ms
    };
    
    esp_err_t initialize() {
        ESP_LOGI(TAG, "Initializing MPU6050");
        
        // Wake up the sensor
        ESP_ERROR_CHECK(writeRegister(PWR_MGMT_1, 0x00));
        vTaskDelay(pdMS_TO_TICKS(100));
        
        // Configure accelerometer (±2g)
        ESP_ERROR_CHECK(writeRegister(ACCEL_CONFIG, 0x00));
        
        // Configure gyroscope (±250°/s)
        ESP_ERROR_CHECK(writeRegister(GYRO_CONFIG, 0x00));
        
        // Set digital low pass filter
        ESP_ERROR_CHECK(writeRegister(CONFIG, 0x03));
        
        // Perform calibration
        ESP_ERROR_CHECK(calibrate());
        
        initialized = true;
        ESP_LOGI(TAG, "MPU6050 initialized successfully");
        
        return ESP_OK;
    }
    
    esp_err_t readData(AccelGyroData& data) {
        if (!initialized) {
            return ESP_ERR_INVALID_STATE;
        }
        
        uint8_t rawData[14];
        ESP_ERROR_CHECK(readRegisters(ACCEL_XOUT_H, rawData, 14));
        
        // Parse raw accelerometer data
        int16_t accelRaw[3] = {
            (int16_t)((rawData[0] << 8) | rawData[1]),   // X
            (int16_t)((rawData[2] << 8) | rawData[3]),   // Y
            (int16_t)((rawData[4] << 8) | rawData[5])    // Z
        };
        
        // Parse raw gyroscope data
        int16_t gyroRaw[3] = {
            (int16_t)((rawData[8] << 8) | rawData[9]),   // X
            (int16_t)((rawData[10] << 8) | rawData[11]), // Y
            (int16_t)((rawData[12] << 8) | rawData[13])  // Z
        };
        
        // Convert to physical units and apply calibration
        data.accelX = (accelRaw[0] / ACCEL_SCALE) - calibrationOffset.accelX;
        data.accelY = (accelRaw[1] / ACCEL_SCALE) - calibrationOffset.accelY;
        data.accelZ = (accelRaw[2] / ACCEL_SCALE) - calibrationOffset.accelZ;
        
        data.gyroX = (gyroRaw[0] / GYRO_SCALE) - calibrationOffset.gyroX;
        data.gyroY = (gyroRaw[1] / GYRO_SCALE) - calibrationOffset.gyroY;
        data.gyroZ = (gyroRaw[2] / GYRO_SCALE) - calibrationOffset.gyroZ;
        
        data.timestamp = esp_timer_get_time() / 1000;  // Convert to ms
        
        return ESP_OK;
    }
    
    esp_err_t calibrate() {
        ESP_LOGI(TAG, "Starting calibration...");
        
        constexpr int numSamples = 100;
        float accelSum[3] = {0, 0, 0};
        float gyroSum[3] = {0, 0, 0};
        
        for (int i = 0; i < numSamples; i++) {
            uint8_t rawData[14];
            ESP_ERROR_CHECK(readRegisters(ACCEL_XOUT_H, rawData, 14));
            
            int16_t accelRaw[3] = {
                (int16_t)((rawData[0] << 8) | rawData[1]),
                (int16_t)((rawData[2] << 8) | rawData[3]),
                (int16_t)((rawData[4] << 8) | rawData[5])
            };
            
            int16_t gyroRaw[3] = {
                (int16_t)((rawData[8] << 8) | rawData[9]),
                (int16_t)((rawData[10] << 8) | rawData[11]),
                (int16_t)((rawData[12] << 8) | rawData[13])
            };
            
            accelSum[0] += accelRaw[0] / ACCEL_SCALE;
            accelSum[1] += accelRaw[1] / ACCEL_SCALE;
            accelSum[2] += accelRaw[2] / ACCEL_SCALE;
            
            gyroSum[0] += gyroRaw[0] / GYRO_SCALE;
            gyroSum[1] += gyroRaw[1] / GYRO_SCALE;
            gyroSum[2] += gyroRaw[2] / GYRO_SCALE;
            
            vTaskDelay(pdMS_TO_TICKS(10));
        }
        
        // Calculate offsets (assuming device is level for accel calibration)
        calibrationOffset.accelX = accelSum[0] / numSamples;
        calibrationOffset.accelY = accelSum[1] / numSamples;
        calibrationOffset.accelZ = (accelSum[2] / numSamples) - 1.0f;  // Remove gravity
        
        calibrationOffset.gyroX = gyroSum[0] / numSamples;
        calibrationOffset.gyroY = gyroSum[1] / numSamples;
        calibrationOffset.gyroZ = gyroSum[2] / numSamples;
        
        ESP_LOGI(TAG, "Calibration complete");
        return ESP_OK;
    }
    
private:
    esp_err_t writeRegister(uint8_t reg, uint8_t value) {
        i2c_cmd_handle_t cmd = i2c_cmd_link_create();
        i2c_master_start(cmd);
        i2c_master_write_byte(cmd, (MPU6050_ADDR << 1) | I2C_MASTER_WRITE, true);
        i2c_master_write_byte(cmd, reg, true);
        i2c_master_write_byte(cmd, value, true);
        i2c_master_stop(cmd);
        
        esp_err_t ret = i2c_master_cmd_begin(I2C_NUM_0, cmd, pdMS_TO_TICKS(1000));
        i2c_cmd_link_delete(cmd);
        
        return ret;
    }
    
    esp_err_t readRegisters(uint8_t reg, uint8_t* data, size_t len) {
        i2c_cmd_handle_t cmd = i2c_cmd_link_create();
        i2c_master_start(cmd);
        i2c_master_write_byte(cmd, (MPU6050_ADDR << 1) | I2C_MASTER_WRITE, true);
        i2c_master_write_byte(cmd, reg, true);
        i2c_master_start(cmd);
        i2c_master_write_byte(cmd, (MPU6050_ADDR << 1) | I2C_MASTER_READ, true);
        i2c_master_read(cmd, data, len, I2C_MASTER_LAST_NACK);
        i2c_master_stop(cmd);
        
        esp_err_t ret = i2c_master_cmd_begin(I2C_NUM_0, cmd, pdMS_TO_TICKS(1000));
        i2c_cmd_link_delete(cmd);
        
        return ret;
    }
};
```

### Force Sensitive Resistors (FSR)
```cpp
// sensors/fsr.cpp
#include "fsr.h"
#include "driver/adc.h"
#include "esp_adc_cal.h"

class FSRManager {
private:
    static constexpr char TAG[] = "FSR";
    static constexpr int NUM_FSR_SENSORS = 4;
    
    adc1_channel_t fsrChannels[NUM_FSR_SENSORS] = {
        ADC1_CHANNEL_6,  // GPIO34
        ADC1_CHANNEL_7,  // GPIO35
        ADC1_CHANNEL_0,  // GPIO36
        ADC1_CHANNEL_3   // GPIO39
    };
    
    esp_adc_cal_characteristics_t adcChars;
    bool initialized = false;
    
    // Calibration values (resistance to force conversion)
    float resistanceToForce[NUM_FSR_SENSORS][2] = {
        {1000.0f, 10.0f},  // FSR 1: R_pullup, sensitivity
        {1000.0f, 10.0f},  // FSR 2
        {1000.0f, 10.0f},  // FSR 3
        {1000.0f, 10.0f}   // FSR 4
    };
    
public:
    struct FSRData {
        float forces[NUM_FSR_SENSORS];  // in Newtons
        float totalForce;               // Sum of all forces
        float centerOfPressure[2];      // X, Y coordinates
        uint32_t timestamp;
    };
    
    esp_err_t initialize() {
        ESP_LOGI(TAG, "Initializing FSR sensors");
        
        // Configure ADC
        adc1_config_width(ADC_WIDTH_BIT_12);
        
        for (int i = 0; i < NUM_FSR_SENSORS; i++) {
            adc1_config_channel_atten(fsrChannels[i], ADC_ATTEN_DB_11);
        }
        
        // Characterize ADC
        esp_adc_cal_value_t valType = esp_adc_cal_characterize(
            ADC_UNIT_1,
            ADC_ATTEN_DB_11,
            ADC_WIDTH_BIT_12,
            1100,  // Default Vref
            &adcChars
        );
        
        if (valType == ESP_ADC_CAL_VAL_EFUSE_VREF) {
            ESP_LOGI(TAG, "Using eFuse Vref");
        } else if (valType == ESP_ADC_CAL_VAL_EFUSE_TP) {
            ESP_LOGI(TAG, "Using eFuse Two Point Value");
        } else {
            ESP_LOGI(TAG, "Using Default Vref");
        }
        
        initialized = true;
        ESP_LOGI(TAG, "FSR sensors initialized");
        
        return ESP_OK;
    }
    
    esp_err_t readData(FSRData& data) {
        if (!initialized) {
            return ESP_ERR_INVALID_STATE;
        }
        
        data.totalForce = 0.0f;
        float weightedX = 0.0f, weightedY = 0.0f;
        
        // Sensor positions (normalized coordinates)
        float sensorPositions[NUM_FSR_SENSORS][2] = {
            {0.25f, 0.75f},  // Top-left
            {0.75f, 0.75f},  // Top-right
            {0.25f, 0.25f},  // Bottom-left
            {0.75f, 0.25f}   // Bottom-right
        };
        
        for (int i = 0; i < NUM_FSR_SENSORS; i++) {
            uint32_t adcReading = adc1_get_raw(fsrChannels[i]);
            uint32_t voltage = esp_adc_cal_raw_to_voltage(adcReading, &adcChars);
            
            // Convert voltage to resistance
            float resistance = calculateResistance(voltage);
            
            // Convert resistance to force using calibration curve
            data.forces[i] = resistanceToForce(resistance, i);
            
            // Accumulate for center of pressure calculation
            data.totalForce += data.forces[i];
            weightedX += data.forces[i] * sensorPositions[i][0];
            weightedY += data.forces[i] * sensorPositions[i][1];
        }
        
        // Calculate center of pressure
        if (data.totalForce > 0.1f) {  // Minimum threshold
            data.centerOfPressure[0] = weightedX / data.totalForce;
            data.centerOfPressure[1] = weightedY / data.totalForce;
        } else {
            data.centerOfPressure[0] = 0.5f;  // Center
            data.centerOfPressure[1] = 0.5f;
        }
        
        data.timestamp = esp_timer_get_time() / 1000;
        
        return ESP_OK;
    }
    
private:
    float calculateResistance(uint32_t voltage_mv) {
        const float VCC = 3300.0f;  // Supply voltage in mV
        const float R_PULLUP = 10000.0f;  // Pull-up resistor value
        
        if (voltage_mv >= VCC) return 1e6;  // Very high resistance
        
        float resistance = R_PULLUP * voltage_mv / (VCC - voltage_mv);
        return resistance;
    }
    
    float resistanceToForce(float resistance, int sensorIndex) {
        // Simple inverse relationship with calibration
        float R_pullup = resistanceToForce[sensorIndex][0];
        float sensitivity = resistanceToForce[sensorIndex][1];
        
        if (resistance > R_pullup) return 0.0f;
        
        // Force = k / R (simplified model)
        float force = sensitivity * 1000.0f / resistance;
        
        // Apply reasonable limits
        if (force < 0.1f) force = 0.0f;
        if (force > 50.0f) force = 50.0f;  // Max 50N
        
        return force;
    }
};
```

---

## 📶 BLE Communication

### BLE GATT Server Implementation
```cpp
// ble/ble_server.cpp
#include "ble_server.h"
#include "esp_bt.h"
#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
#include "esp_bt_main.h"

class BLEServer {
private:
    static constexpr char TAG[] = "BLE_SERVER";
    
    // Service and Characteristic UUIDs
    static constexpr uint8_t DEVICE_INFO_SERVICE_UUID[16] = {
        0xAB, 0xCD, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC,
        0xDE, 0xF0, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC
    };
    
    static constexpr uint8_t SENSOR_DATA_CHAR_UUID[16] = {
        0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0,
        0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0
    };
    
    uint16_t gattIfaceId = ESP_GATT_IF_NONE;
    uint16_t appId = 0;
    uint16_t connId = 0xFFFF;
    uint16_t serviceHandle = 0;
    uint16_t charHandle = 0;
    
    bool isConnected = false;
    bool isAdvertising = false;
    
    struct {
        uint8_t deviceId[16];
        uint8_t firmwareVersion[16];
        uint32_t batteryLevel;
    } deviceInfo;
    
public:
    esp_err_t initialize() {
        ESP_LOGI(TAG, "Initializing BLE server");
        
        // Initialize NVS
        ESP_ERROR_CHECK(nvs_flash_init());
        
        // Initialize Bluetooth controller
        esp_bt_controller_config_t btCfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
        ESP_ERROR_CHECK(esp_bt_controller_init(&btCfg));
        ESP_ERROR_CHECK(esp_bt_controller_enable(ESP_BT_MODE_BLE));
        
        // Initialize Bluedroid stack
        ESP_ERROR_CHECK(esp_bluedroid_init());
        ESP_ERROR_CHECK(esp_bluedroid_enable());
        
        // Register callbacks
        ESP_ERROR_CHECK(esp_ble_gatts_register_callback(gattsEventHandler));
        ESP_ERROR_CHECK(esp_ble_gap_register_callback(gapEventHandler));
        
        // Register application
        ESP_ERROR_CHECK(esp_ble_gatts_app_register(appId));
        
        // Configure advertising data
        setupAdvertising();
        
        ESP_LOGI(TAG, "BLE server initialized");
        return ESP_OK;
    }
    
    esp_err_t sendSensorData(const SensorDataPacket& packet) {
        if (!isConnected) {
            return ESP_ERR_INVALID_STATE;
        }
        
        uint8_t data[64];
        size_t dataLen = packet.serialize(data, sizeof(data));
        
        return esp_ble_gatts_send_indicate(
            gattIfaceId,
            connId,
            charHandle,
            dataLen,
            data,
            false  // No confirmation needed
        );
    }
    
    esp_err_t startAdvertising() {
        if (isAdvertising) {
            return ESP_OK;
        }
        
        ESP_ERROR_CHECK(esp_ble_gap_start_advertising(&advParams));
        isAdvertising = true;
        
        ESP_LOGI(TAG, "Started BLE advertising");
        return ESP_OK;
    }
    
    esp_err_t stopAdvertising() {
        if (!isAdvertising) {
            return ESP_OK;
        }
        
        ESP_ERROR_CHECK(esp_ble_gap_stop_advertising());
        isAdvertising = false;
        
        ESP_LOGI(TAG, "Stopped BLE advertising");
        return ESP_OK;
    }
    
    bool getConnectionStatus() const {
        return isConnected;
    }
    
private:
    static void gattsEventHandler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param) {
        BLEServer* instance = BLEServer::getInstance();
        instance->handleGattsEvent(event, gatts_if, param);
    }
    
    static void gapEventHandler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param) {
        BLEServer* instance = BLEServer::getInstance();
        instance->handleGapEvent(event, param);
    }
    
    void handleGattsEvent(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param) {
        switch (event) {
            case ESP_GATTS_REG_EVT: {
                gattIfaceId = gatts_if;
                
                // Set device name
                esp_ble_gap_set_device_name("OrthoTrack-ESP32");
                
                // Create service
                esp_ble_gatts_create_service(gatts_if, &serviceId, GATTS_NUM_HANDLE_TEST_A);
                break;
            }
            
            case ESP_GATTS_CREATE_EVT: {
                serviceHandle = param->create.service_handle;
                
                // Start service
                esp_ble_gatts_start_service(serviceHandle);
                
                // Add characteristics
                addCharacteristics();
                break;
            }
            
            case ESP_GATTS_CONNECT_EVT: {
                connId = param->connect.conn_id;
                isConnected = true;
                
                ESP_LOGI(TAG, "Device connected, conn_id = %d", connId);
                
                // Stop advertising
                stopAdvertising();
                break;
            }
            
            case ESP_GATTS_DISCONNECT_EVT: {
                isConnected = false;
                connId = 0xFFFF;
                
                ESP_LOGI(TAG, "Device disconnected");
                
                // Restart advertising
                startAdvertising();
                break;
            }
            
            case ESP_GATTS_WRITE_EVT: {
                // Handle incoming commands
                handleIncomingCommand(param->write.value, param->write.len);
                break;
            }
            
            default:
                break;
        }
    }
    
    void handleIncomingCommand(uint8_t* data, uint16_t len) {
        if (len < 1) return;
        
        uint8_t command = data[0];
        
        switch (command) {
            case CMD_START_SESSION:
                ESP_LOGI(TAG, "Received START_SESSION command");
                // Start data collection
                break;
                
            case CMD_STOP_SESSION:
                ESP_LOGI(TAG, "Received STOP_SESSION command");
                // Stop data collection
                break;
                
            case CMD_SET_CONFIG:
                ESP_LOGI(TAG, "Received SET_CONFIG command");
                // Update configuration
                break;
                
            case CMD_CALIBRATE:
                ESP_LOGI(TAG, "Received CALIBRATE command");
                // Trigger sensor calibration
                break;
                
            default:
                ESP_LOGW(TAG, "Unknown command: 0x%02X", command);
                break;
        }
    }
};
```

---

## 🤖 AI/ML Integration (TinyML)

### TensorFlow Lite Micro
```cpp
// ai/tinyml.cpp
#include "tinyml.h"
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

// Include the model (generated from Python training)
#include "movement_detection_model.h"

class TinyMLProcessor {
private:
    static constexpr char TAG[] = "TinyML";
    static constexpr size_t TENSOR_ARENA_SIZE = 60 * 1024;  // 60KB
    
    tflite::MicroErrorReporter errorReporter;
    const tflite::Model* model = nullptr;
    tflite::MicroInterpreter* interpreter = nullptr;
    tflite::AllOpsResolver resolver;
    
    alignas(16) uint8_t tensorArena[TENSOR_ARENA_SIZE];
    
    TfLiteTensor* inputTensor = nullptr;
    TfLiteTensor* outputTensor = nullptr;
    
    bool initialized = false;
    
    // Sliding window for sensor data
    static constexpr size_t WINDOW_SIZE = 50;  // 50 samples @ 20Hz = 2.5 seconds
    static constexpr size_t INPUT_FEATURES = 6;  // accel X,Y,Z + gyro X,Y,Z
    
    float sensorWindow[WINDOW_SIZE][INPUT_FEATURES];
    size_t windowIndex = 0;
    bool windowFilled = false;
    
public:
    struct MLResult {
        bool isWearing;          // Wearing detection confidence
        float wearingConfidence; // 0.0 - 1.0
        
        enum MovementType {
            STATIONARY = 0,
            WALKING = 1,
            RUNNING = 2,
            SITTING = 3,
            LYING_DOWN = 4
        } movementType;
        
        float movementConfidence;
        
        enum PostureQuality {
            GOOD = 0,
            FAIR = 1,
            POOR = 2
        } postureQuality;
        
        float postureScore;  // 0.0 - 1.0
    };
    
    esp_err_t initialize() {
        ESP_LOGI(TAG, "Initializing TinyML processor");
        
        // Load model
        model = tflite::GetModel(movement_detection_model);
        if (model->version() != TFLITE_SCHEMA_VERSION) {
            ESP_LOGE(TAG, "Model version mismatch");
            return ESP_FAIL;
        }
        
        // Create interpreter
        static tflite::MicroInterpreter staticInterpreter(
            model, resolver, tensorArena, TENSOR_ARENA_SIZE, &errorReporter
        );
        interpreter = &staticInterpreter;
        
        // Allocate tensors
        TfLiteStatus allocateStatus = interpreter->AllocateTensors();
        if (allocateStatus != kTfLiteOk) {
            ESP_LOGE(TAG, "Failed to allocate tensors");
            return ESP_FAIL;
        }
        
        // Get input and output tensors
        inputTensor = interpreter->input(0);
        outputTensor = interpreter->output(0);
        
        // Verify tensor dimensions
        if (inputTensor->dims->size != 2 || 
            inputTensor->dims->data[0] != WINDOW_SIZE ||
            inputTensor->dims->data[1] != INPUT_FEATURES) {
            ESP_LOGE(TAG, "Input tensor dimensions mismatch");
            return ESP_FAIL;
        }
        
        // Initialize sensor window
        memset(sensorWindow, 0, sizeof(sensorWindow));
        
        initialized = true;
        ESP_LOGI(TAG, "TinyML processor initialized successfully");
        
        return ESP_OK;
    }
    
    esp_err_t processSensorData(const MPU6050::AccelGyroData& data, MLResult& result) {
        if (!initialized) {
            return ESP_ERR_INVALID_STATE;
        }
        
        // Add new data to sliding window
        sensorWindow[windowIndex][0] = data.accelX;
        sensorWindow[windowIndex][1] = data.accelY;
        sensorWindow[windowIndex][2] = data.accelZ;
        sensorWindow[windowIndex][3] = data.gyroX;
        sensorWindow[windowIndex][4] = data.gyroY;
        sensorWindow[windowIndex][5] = data.gyroZ;
        
        windowIndex = (windowIndex + 1) % WINDOW_SIZE;
        if (!windowFilled && windowIndex == 0) {
            windowFilled = true;
        }
        
        // Only run inference when window is filled
        if (!windowFilled) {
            result.isWearing = false;
            result.wearingConfidence = 0.0f;
            result.movementType = MLResult::STATIONARY;
            result.movementConfidence = 0.0f;
            result.postureQuality = MLResult::GOOD;
            result.postureScore = 1.0f;
            return ESP_OK;
        }
        
        // Normalize and copy data to input tensor
        normalizeAndCopyToInput();
        
        // Run inference
        TfLiteStatus invokeStatus = interpreter->Invoke();
        if (invokeStatus != kTfLiteOk) {
            ESP_LOGE(TAG, "Failed to invoke model");
            return ESP_FAIL;
        }
        
        // Parse output
        parseModelOutput(result);
        
        return ESP_OK;
    }
    
private:
    void normalizeAndCopyToInput() {
        // Calculate normalization parameters from current window
        float mean[INPUT_FEATURES] = {0};
        float stddev[INPUT_FEATURES] = {0};
        
        // Calculate mean
        for (size_t i = 0; i < WINDOW_SIZE; i++) {
            for (size_t j = 0; j < INPUT_FEATURES; j++) {
                mean[j] += sensorWindow[i][j];
            }
        }
        for (size_t j = 0; j < INPUT_FEATURES; j++) {
            mean[j] /= WINDOW_SIZE;
        }
        
        // Calculate standard deviation
        for (size_t i = 0; i < WINDOW_SIZE; i++) {
            for (size_t j = 0; j < INPUT_FEATURES; j++) {
                float diff = sensorWindow[i][j] - mean[j];
                stddev[j] += diff * diff;
            }
        }
        for (size_t j = 0; j < INPUT_FEATURES; j++) {
            stddev[j] = sqrtf(stddev[j] / WINDOW_SIZE);
            if (stddev[j] < 1e-6f) stddev[j] = 1.0f;  // Prevent division by zero
        }
        
        // Normalize and copy to input tensor
        float* inputData = inputTensor->data.f;
        for (size_t i = 0; i < WINDOW_SIZE; i++) {
            for (size_t j = 0; j < INPUT_FEATURES; j++) {
                size_t actualIndex = (windowIndex + i) % WINDOW_SIZE;
                inputData[i * INPUT_FEATURES + j] = 
                    (sensorWindow[actualIndex][j] - mean[j]) / stddev[j];
            }
        }
    }
    
    void parseModelOutput(MLResult& result) {
        float* outputData = outputTensor->data.f;
        
        // Assuming model outputs:
        // [0] - wearing probability
        // [1-5] - movement type probabilities (stationary, walking, running, sitting, lying)
        // [6-8] - posture quality probabilities (good, fair, poor)
        
        // Wearing detection
        result.wearingConfidence = outputData[0];
        result.isWearing = result.wearingConfidence > 0.5f;
        
        // Movement classification
        float maxMovementProb = 0.0f;
        int maxMovementIndex = 0;
        for (int i = 1; i <= 5; i++) {
            if (outputData[i] > maxMovementProb) {
                maxMovementProb = outputData[i];
                maxMovementIndex = i - 1;
            }
        }
        result.movementType = static_cast<MLResult::MovementType>(maxMovementIndex);
        result.movementConfidence = maxMovementProb;
        
        // Posture quality
        float maxPostureProb = 0.0f;
        int maxPostureIndex = 0;
        for (int i = 6; i <= 8; i++) {
            if (outputData[i] > maxPostureProb) {
                maxPostureProb = outputData[i];
                maxPostureIndex = i - 6;
            }
        }
        result.postureQuality = static_cast<MLResult::PostureQuality>(maxPostureIndex);
        result.postureScore = 1.0f - (maxPostureIndex / 2.0f);  // Convert to 0-1 score
    }
};
```

---

## ⚡ Power Management

### Sleep and Power Optimization
```cpp
// power/power_manager.cpp
#include "power_manager.h"
#include "esp_pm.h"
#include "esp_sleep.h"
#include "esp_wifi.h"
#include "esp_bt.h"
#include "driver/rtc_io.h"

class PowerManager {
private:
    static constexpr char TAG[] = "PowerManager";
    
    enum PowerMode {
        ACTIVE,      // Full operation
        LOW_POWER,   // Reduced sampling rate
        SLEEP,       // Deep sleep when inactive
        SHUTDOWN     // Emergency shutdown
    };
    
    PowerMode currentMode = ACTIVE;
    bool isWearing = false;
    uint32_t lastActivityTime = 0;
    uint32_t batteryLevel = 100;
    
    // Thresholds
    static constexpr uint32_t INACTIVITY_TIMEOUT = 30 * 60 * 1000;  // 30 minutes
    static constexpr uint32_t LOW_BATTERY_THRESHOLD = 20;           // 20%
    static constexpr uint32_t CRITICAL_BATTERY_THRESHOLD = 5;       // 5%
    
public:
    esp_err_t initialize() {
        ESP_LOGI(TAG, "Initializing power management");
        
        // Configure power management
        esp_pm_config_esp32_t pmConfig = {
            .max_freq_mhz = 240,     // Maximum CPU frequency
            .min_freq_mhz = 10,      // Minimum CPU frequency in light sleep
            .light_sleep_enable = true
        };
        ESP_ERROR_CHECK(esp_pm_configure(&pmConfig));
        
        // Configure wake-up sources
        setupWakeupSources();
        
        ESP_LOGI(TAG, "Power management initialized");
        return ESP_OK;
    }
    
    void updatePowerMode(bool wearing, uint32_t battery) {
        isWearing = wearing;
        batteryLevel = battery;
        
        if (wearing) {
            lastActivityTime = esp_timer_get_time() / 1000;
        }
        
        PowerMode newMode = calculateOptimalMode();
        
        if (newMode != currentMode) {
            transitionToMode(newMode);
            currentMode = newMode;
        }
    }
    
    void enterDeepSleep() {
        ESP_LOGI(TAG, "Entering deep sleep");
        
        // Save critical data to RTC memory
        saveStateToRTC();
        
        // Disable non-essential peripherals
        disablePeripherals();
        
        // Set wake-up timer (30 seconds for status check)
        esp_sleep_enable_timer_wakeup(30 * 1000000ULL);  // 30 seconds in microseconds
        
        // Enter deep sleep
        esp_deep_sleep_start();
    }
    
    uint32_t getEstimatedBatteryLife() {
        // Estimate remaining battery life based on current consumption
        float currentConsumption = getCurrentConsumption();
        float remainingCapacity = batteryLevel * 0.01f * BATTERY_CAPACITY_MAH;
        
        return (uint32_t)(remainingCapacity / currentConsumption);  // Hours
    }
    
    void handleLowBattery() {
        ESP_LOGW(TAG, "Low battery detected: %d%%", batteryLevel);
        
        // Reduce functionality
        if (batteryLevel < CRITICAL_BATTERY_THRESHOLD) {
            // Emergency shutdown
            ESP_LOGE(TAG, "Critical battery level, shutting down");
            emergencyShutdown();
        } else if (batteryLevel < LOW_BATTERY_THRESHOLD) {
            // Reduce power consumption
            transitionToMode(LOW_POWER);
        }
    }
    
private:
    PowerMode calculateOptimalMode() {
        uint32_t currentTime = esp_timer_get_time() / 1000;
        uint32_t timeSinceActivity = currentTime - lastActivityTime;
        
        if (batteryLevel < CRITICAL_BATTERY_THRESHOLD) {
            return SHUTDOWN;
        } else if (batteryLevel < LOW_BATTERY_THRESHOLD) {
            return LOW_POWER;
        } else if (!isWearing && timeSinceActivity > INACTIVITY_TIMEOUT) {
            return SLEEP;
        } else {
            return ACTIVE;
        }
    }
    
    void transitionToMode(PowerMode mode) {
        ESP_LOGI(TAG, "Transitioning to power mode: %d", mode);
        
        switch (mode) {
            case ACTIVE:
                // Full operation - 20Hz sampling
                setSamplingRate(50);  // 50ms interval
                enableAllSensors();
                enableBLE();
                break;
                
            case LOW_POWER:
                // Reduced operation - 5Hz sampling
                setSamplingRate(200);  // 200ms interval
                enableAllSensors();
                enableBLE();
                break;
                
            case SLEEP:
                // Minimal operation - 1Hz sampling
                setSamplingRate(1000);  // 1000ms interval
                disableNonEssentialSensors();
                enableBLE();  // Keep BLE for wake-up
                break;
                
            case SHUTDOWN:
                // Emergency shutdown
                emergencyShutdown();
                break;
        }
    }
    
    void setupWakeupSources() {
        // Enable wake-up on accelerometer interrupt (movement detection)
        esp_sleep_enable_ext0_wakeup(GPIO_NUM_4, 1);  // Accelerometer INT pin
        
        // Enable wake-up on timer
        esp_sleep_enable_timer_wakeup(30 * 1000000ULL);  // 30 seconds
        
        // Enable wake-up on BLE connection
        esp_sleep_enable_uart_wakeup(0);
    }
    
    float getCurrentConsumption() {
        // Estimate current consumption based on active components
        float consumption = 20.0f;  // Base consumption (mA)
        
        switch (currentMode) {
            case ACTIVE:
                consumption += 80.0f;  // Full sensors + BLE
                break;
            case LOW_POWER:
                consumption += 40.0f;  // Reduced sensors + BLE
                break;
            case SLEEP:
                consumption += 10.0f;  // Minimal sensors + BLE
                break;
            default:
                consumption = 5.0f;    // Deep sleep
                break;
        }
        
        return consumption;
    }
    
    void emergencyShutdown() {
        ESP_LOGE(TAG, "Emergency shutdown initiated");
        
        // Save critical data
        saveStateToRTC();
        
        // Send emergency alert if BLE connected
        sendEmergencyAlert();
        
        // Disable all peripherals
        disablePeripherals();
        
        // Enter deep sleep indefinitely
        esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_ALL);
        esp_sleep_enable_timer_wakeup(24 * 3600 * 1000000ULL);  // 24 hours
        esp_deep_sleep_start();
    }
};
```

---

## 🔧 Build Configuration

### PlatformIO Configuration
```ini
; platformio.ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino

; Build flags
build_flags = 
    -DCORE_DEBUG_LEVEL=3
    -DCONFIG_ARDUHAL_LOG_COLORS
    -DTFLITE_MICRO
    -DTF_LITE_STATIC_MEMORY
    -DTF_LITE_MCU_DEBUG_LOG

; Libraries
lib_deps = 
    adafruit/DHT sensor library@^1.4.4
    adafruit/Adafruit MPU6050@^2.2.4
    arduino-libraries/ArduinoJson@^6.21.3
    tinyml/tflite-micro-arduino@^1.0.0

; Upload settings
upload_speed = 921600
monitor_speed = 115200
monitor_filters = 
    esp32_exception_decoder
    time

; Partition scheme for larger app
board_build.partitions = huge_app.csv

[env:release]
extends = env:esp32dev
build_type = release
build_flags = 
    ${env:esp32dev.build_flags}
    -DNDEBUG
    -Os

[env:debug]
extends = env:esp32dev
build_type = debug
build_flags = 
    ${env:esp32dev.build_flags}
    -DDEBUG
    -O0
    -g
```

### CMakeLists.txt for ESP-IDF
```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.16)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)

set(COMPONENT_SRCS 
    "src/main.cpp"
    "src/sensors/mpu6050.cpp"
    "src/sensors/dht22.cpp"
    "src/sensors/fsr.cpp"
    "src/sensors/battery.cpp"
    "src/ble/ble_server.cpp"
    "src/ble/ble_callbacks.cpp"
    "src/ai/tinyml.cpp"
    "src/power/power_manager.cpp"
    "src/storage/nvs_manager.cpp"
    "src/utils/logger.cpp"
)

set(COMPONENT_ADD_INCLUDEDIRS 
    "src"
    "include"
    "lib/tflite-micro"
)

project(orthotrack-esp32)
```

---

## 📊 Performance Specifications

### Target Performance Metrics
```cpp
// Performance targets
namespace Performance {
    constexpr uint32_t SENSOR_SAMPLE_RATE_HZ = 20;      // 20 Hz sampling
    constexpr uint32_t BLE_DATA_RATE_HZ = 5;            // 5 Hz BLE transmission
    constexpr uint32_t AI_INFERENCE_RATE_HZ = 2;        // 2 Hz ML inference
    
    constexpr uint32_t MAX_SENSOR_LATENCY_MS = 50;      // < 50ms sensor latency
    constexpr uint32_t MAX_BLE_LATENCY_MS = 200;        // < 200ms BLE latency
    constexpr uint32_t MAX_AI_LATENCY_MS = 500;         // < 500ms AI inference
    
    constexpr uint32_t BATTERY_LIFE_HOURS = 72;         // 72+ hours operation
    constexpr uint32_t DEEP_SLEEP_CURRENT_UA = 50;      // < 50µA deep sleep
    constexpr uint32_t ACTIVE_CURRENT_MA = 100;         // < 100mA active mode
}
```

### Memory Usage
```cpp
// Memory allocation targets
namespace Memory {
    constexpr size_t TOTAL_HEAP_SIZE = 320 * 1024;      // 320KB total heap
    constexpr size_t AI_MODEL_SIZE = 64 * 1024;         // 64KB AI model
    constexpr size_t SENSOR_BUFFER_SIZE = 16 * 1024;    // 16KB sensor buffer
    constexpr size_t BLE_BUFFER_SIZE = 8 * 1024;        // 8KB BLE buffer
    constexpr size_t STACK_SIZE_TOTAL = 32 * 1024;      // 32KB total stacks
    constexpr size_t FREE_HEAP_MIN = 64 * 1024;         // 64KB minimum free
}
```

---

**Documentação Técnica - ESP32 Firmware**  
**Versão**: 1.0  
**Última Atualização**: 2024-12-03