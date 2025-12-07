# Android Edge Node Technical Specifications

## 📱 Arquitetura Android

### Stack Tecnológico
- **Language**: Kotlin + Java (legacy support)
- **Min SDK**: Android 8.0 (API 26) - Required for BLE features
- **Target SDK**: Android 14 (API 34)
- **Architecture**: MVVM + Clean Architecture
- **DI**: Hilt (Dagger)
- **Database**: Room (SQLite)
- **HTTP**: OkHttp + Retrofit
- **Async**: Coroutines + Flow
- **Background**: WorkManager
- **BLE**: Android Bluetooth LE API
- **UI**: Jetpack Compose + Material 3

### Estrutura do Projeto
```
android-edge-node/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/orthotrack/edgenode/
│   │   │   │   ├── data/           # Data layer
│   │   │   │   │   ├── local/      # Room database, SharedPrefs
│   │   │   │   │   ├── remote/     # API services
│   │   │   │   │   ├── repository/ # Repository implementations
│   │   │   │   │   └── models/     # Data models
│   │   │   │   ├── domain/         # Domain layer
│   │   │   │   │   ├── entities/   # Domain entities
│   │   │   │   │   ├── usecases/   # Business logic
│   │   │   │   │   └── repository/ # Repository interfaces
│   │   │   │   ├── presentation/   # Presentation layer
│   │   │   │   │   ├── ui/         # Compose UI screens
│   │   │   │   │   ├── viewmodel/  # ViewModels
│   │   │   │   │   └── theme/      # UI theme
│   │   │   │   ├── ble/            # Bluetooth LE module
│   │   │   │   │   ├── scanner/    # Device discovery
│   │   │   │   │   ├── connection/ # Connection management
│   │   │   │   │   ├── protocol/   # Communication protocol
│   │   │   │   │   └── services/   # BLE services
│   │   │   │   ├── sync/           # Data synchronization
│   │   │   │   │   ├── worker/     # Background sync workers
│   │   │   │   │   ├── queue/      # Offline data queue
│   │   │   │   │   └── conflict/   # Conflict resolution
│   │   │   │   ├── notification/   # Push notifications
│   │   │   │   ├── analytics/      # Local analytics
│   │   │   │   ├── security/       # Security & encryption
│   │   │   │   └── utils/          # Utility classes
│   │   │   ├── res/               # Resources
│   │   │   └── AndroidManifest.xml
│   │   ├── test/                  # Unit tests
│   │   └── androidTest/           # Integration tests
│   ├── build.gradle               # App-level Gradle
│   └── proguard-rules.pro         # ProGuard rules
├── build.gradle                   # Project-level Gradle
├── gradle.properties              # Gradle properties
└── settings.gradle                # Gradle settings
```

---

## 🔗 Bluetooth LE Architecture

### BLE Service Discovery
```kotlin
// ble/scanner/BleScanner.kt
@Singleton
class BleScanner @Inject constructor(
    private val bluetoothAdapter: BluetoothAdapter,
    private val context: Context
) {
    
    companion object {
        private val ORTHOTRACK_SERVICE_UUID = UUID.fromString("12345678-1234-1234-1234-123456789abc")
        private const val SCAN_TIMEOUT_MS = 30000L
    }
    
    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device
            val serviceUuids = result.scanRecord?.serviceUuids
            
            // Filter for OrthoTrack devices
            if (serviceUuids?.any { it.uuid == ORTHOTRACK_SERVICE_UUID } == true) {
                _devicesFound.value = _devicesFound.value + device
            }
        }
        
        override fun onScanFailed(errorCode: Int) {
            _scanState.value = ScanState.Error("Scan failed: $errorCode")
        }
    }
    
    private val _devicesFound = MutableStateFlow<List<BluetoothDevice>>(emptyList())
    val devicesFound = _devicesFound.asStateFlow()
    
    private val _scanState = MutableStateFlow(ScanState.Idle)
    val scanState = _scanState.asStateFlow()
    
    suspend fun startScan(): Flow<ScanState> = callbackFlow {
        if (!bluetoothAdapter.isEnabled) {
            send(ScanState.Error("Bluetooth not enabled"))
            return@callbackFlow
        }
        
        val scanner = bluetoothAdapter.bluetoothLeScanner
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
            .build()
        
        val filters = listOf(
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(ORTHOTRACK_SERVICE_UUID))
                .build()
        )
        
        send(ScanState.Scanning)
        scanner.startScan(filters, settings, scanCallback)
        
        // Auto-stop after timeout
        delay(SCAN_TIMEOUT_MS)
        scanner.stopScan(scanCallback)
        send(ScanState.Completed)
        
        awaitClose { scanner.stopScan(scanCallback) }
    }
}
```

### BLE Connection Management
```kotlin
// ble/connection/BleConnectionManager.kt
@Singleton
class BleConnectionManager @Inject constructor(
    private val context: Context,
    private val dataProcessor: BleDataProcessor
) {
    
    private val connections = mutableMapOf<String, BleDeviceConnection>()
    
    suspend fun connectToDevice(device: BluetoothDevice): Flow<ConnectionState> = callbackFlow {
        val deviceAddress = device.address
        
        if (connections.containsKey(deviceAddress)) {
            send(ConnectionState.Connected)
            return@callbackFlow
        }
        
        send(ConnectionState.Connecting)
        
        val gattCallback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        trySend(ConnectionState.Connected)
                        gatt.discoverServices()
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        connections.remove(deviceAddress)
                        trySend(ConnectionState.Disconnected)
                        gatt.close()
                    }
                }
            }
            
            override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    val connection = BleDeviceConnection(gatt, device, dataProcessor)
                    connections[deviceAddress] = connection
                    connection.setupNotifications()
                }
            }
            
            override fun onCharacteristicChanged(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                value: ByteArray
            ) {
                val connection = connections[deviceAddress]
                connection?.processIncomingData(characteristic.uuid, value)
            }
        }
        
        val gatt = device.connectGatt(context, false, gattCallback)
        
        awaitClose { 
            gatt.disconnect()
            gatt.close()
        }
    }
    
    fun getConnection(deviceAddress: String): BleDeviceConnection? {
        return connections[deviceAddress]
    }
    
    fun disconnectDevice(deviceAddress: String) {
        connections[deviceAddress]?.disconnect()
        connections.remove(deviceAddress)
    }
    
    fun disconnectAll() {
        connections.values.forEach { it.disconnect() }
        connections.clear()
    }
}
```

### BLE Protocol Implementation
```kotlin
// ble/protocol/OrthoTrackProtocol.kt
class OrthoTrackProtocol {
    companion object {
        // Service UUIDs
        val DEVICE_INFO_SERVICE = UUID.fromString("12345678-1234-1234-1234-123456789abc")
        val SENSOR_DATA_SERVICE = UUID.fromString("12345678-1234-1234-1234-123456789abd")
        val COMMAND_SERVICE = UUID.fromString("12345678-1234-1234-1234-123456789abe")
        
        // Characteristic UUIDs
        val DEVICE_ID_CHAR = UUID.fromString("87654321-4321-4321-4321-abcdef123456")
        val BATTERY_LEVEL_CHAR = UUID.fromString("87654321-4321-4321-4321-abcdef123457")
        val SENSOR_DATA_CHAR = UUID.fromString("87654321-4321-4321-4321-abcdef123458")
        val COMMAND_CHAR = UUID.fromString("87654321-4321-4321-4321-abcdef123459")
        
        // Commands
        const val CMD_START_SESSION = 0x01
        const val CMD_STOP_SESSION = 0x02
        const val CMD_SET_CONFIG = 0x03
        const val CMD_GET_STATUS = 0x04
        const val CMD_CALIBRATE = 0x05
    }
    
    data class SensorDataPacket(
        val timestamp: Long,
        val accelX: Float,
        val accelY: Float,
        val accelZ: Float,
        val gyroX: Float,
        val gyroY: Float,
        val gyroZ: Float,
        val temperature: Float,
        val humidity: Float,
        val pressurePoints: FloatArray,
        val batteryVoltage: Float
    ) {
        companion object {
            fun fromByteArray(data: ByteArray): SensorDataPacket {
                val buffer = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN)
                
                return SensorDataPacket(
                    timestamp = buffer.long,
                    accelX = buffer.float,
                    accelY = buffer.float,
                    accelZ = buffer.float,
                    gyroX = buffer.float,
                    gyroY = buffer.float,
                    gyroZ = buffer.float,
                    temperature = buffer.float,
                    humidity = buffer.float,
                    pressurePoints = FloatArray(4) { buffer.float },
                    batteryVoltage = buffer.float
                )
            }
        }
        
        fun toByteArray(): ByteArray {
            val buffer = ByteBuffer.allocate(64).order(ByteOrder.LITTLE_ENDIAN)
            
            buffer.putLong(timestamp)
            buffer.putFloat(accelX)
            buffer.putFloat(accelY)
            buffer.putFloat(accelZ)
            buffer.putFloat(gyroX)
            buffer.putFloat(gyroY)
            buffer.putFloat(gyroZ)
            buffer.putFloat(temperature)
            buffer.putFloat(humidity)
            pressurePoints.forEach { buffer.putFloat(it) }
            buffer.putFloat(batteryVoltage)
            
            return buffer.array()
        }
    }
}
```

---

## 💾 Data Layer

### Room Database
```kotlin
// data/local/database/OrthoTrackDatabase.kt
@Database(
    entities = [
        PatientEntity::class,
        BraceEntity::class,
        SensorReadingEntity::class,
        UsageSessionEntity::class,
        AlertEntity::class,
        SyncQueueEntity::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class OrthoTrackDatabase : RoomDatabase() {
    
    abstract fun patientDao(): PatientDao
    abstract fun braceDao(): BraceDao
    abstract fun sensorReadingDao(): SensorReadingDao
    abstract fun usageSessionDao(): UsageSessionDao
    abstract fun alertDao(): AlertDao
    abstract fun syncQueueDao(): SyncQueueDao
    
    @Module
    @InstallIn(SingletonComponent::class)
    object DatabaseModule {
        
        @Provides
        @Singleton
        fun provideDatabase(@ApplicationContext context: Context): OrthoTrackDatabase {
            return Room.databaseBuilder(
                context,
                OrthoTrackDatabase::class.java,
                "orthotrack_database"
            )
            .fallbackToDestructiveMigration()
            .build()
        }
    }
}

// data/local/entities/SensorReadingEntity.kt
@Entity(
    tableName = "sensor_readings",
    indices = [
        Index(value = ["braceId", "timestamp"]),
        Index(value = ["timestamp"])
    ]
)
data class SensorReadingEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    
    val braceId: String,
    val timestamp: Long,
    
    // Sensor data
    val accelX: Float,
    val accelY: Float,
    val accelZ: Float,
    val gyroX: Float,
    val gyroY: Float,
    val gyroZ: Float,
    val temperature: Float,
    val humidity: Float,
    val pressurePoints: List<Float>,
    val batteryVoltage: Float,
    
    // Processed data
    val isWearing: Boolean,
    val movementLevel: String,
    val postureScore: Float,
    val comfortLevel: String,
    
    // Sync status
    val isSynced: Boolean = false,
    val syncAttempts: Int = 0,
    val lastSyncAttempt: Long? = null,
    
    val createdAt: Long = System.currentTimeMillis()
)
```

### Repository Implementation
```kotlin
// data/repository/SensorDataRepositoryImpl.kt
@Singleton
class SensorDataRepositoryImpl @Inject constructor(
    private val sensorReadingDao: SensorReadingDao,
    private val apiService: OrthoTrackApiService,
    private val syncQueueDao: SyncQueueDao,
    private val dataProcessor: LocalDataProcessor
) : SensorDataRepository {
    
    override suspend fun storeSensorReading(reading: SensorReading): Result<Unit> {
        return try {
            // Process data locally
            val processedReading = dataProcessor.processReading(reading)
            
            // Store in local database
            val entity = processedReading.toEntity()
            sensorReadingDao.insertReading(entity)
            
            // Queue for sync
            val syncItem = SyncQueueEntity(
                type = SyncType.SENSOR_READING,
                entityId = entity.id.toString(),
                data = entity.toJson(),
                priority = SyncPriority.HIGH
            )
            syncQueueDao.insertSyncItem(syncItem)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    override suspend fun getLocalReadings(
        braceId: String,
        limit: Int,
        offset: Int
    ): Flow<List<SensorReading>> {
        return sensorReadingDao.getReadingsByBraceId(braceId, limit, offset)
            .map { entities -> entities.map { it.toDomainModel() } }
    }
    
    override suspend fun syncPendingData(): Result<SyncResult> {
        return try {
            val pendingItems = syncQueueDao.getPendingItems()
            var successful = 0
            var failed = 0
            
            pendingItems.forEach { item ->
                when (item.type) {
                    SyncType.SENSOR_READING -> {
                        val result = syncSensorReading(item)
                        if (result.isSuccess) {
                            successful++
                            syncQueueDao.deleteSyncItem(item.id)
                        } else {
                            failed++
                            syncQueueDao.incrementRetryCount(item.id)
                        }
                    }
                }
            }
            
            Result.success(SyncResult(successful, failed))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    private suspend fun syncSensorReading(item: SyncQueueEntity): Result<Unit> {
        return try {
            val reading = SensorReadingEntity.fromJson(item.data)
            apiService.uploadSensorData(reading.toApiModel())
            
            // Mark as synced in local database
            sensorReadingDao.markAsSynced(reading.id)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
```

---

## 🔄 Background Processing

### Sync WorkManager
```kotlin
// sync/worker/DataSyncWorker.kt
@HiltWorker
class DataSyncWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted workerParams: WorkerParameters,
    private val syncRepository: SyncRepository,
    private val connectivityManager: ConnectivityManager
) : CoroutineWorker(context, workerParams) {
    
    @AssistedFactory
    interface Factory {
        fun create(context: Context, workerParams: WorkerParameters): DataSyncWorker
    }
    
    override suspend fun doWork(): Result {
        return try {
            // Check network connectivity
            if (!isNetworkAvailable()) {
                return Result.retry()
            }
            
            // Sync pending data
            val syncResult = syncRepository.syncAllPendingData()
            
            if (syncResult.isSuccess) {
                val result = syncResult.getOrNull()
                
                // Log sync statistics
                Timber.d("Sync completed: ${result?.successful} successful, ${result?.failed} failed")
                
                // Schedule next sync
                scheduleNextSync()
                
                Result.success()
            } else {
                Timber.e(syncResult.exceptionOrNull(), "Sync failed")
                Result.retry()
            }
        } catch (e: Exception) {
            Timber.e(e, "Unexpected error during sync")
            Result.failure()
        }
    }
    
    private fun isNetworkAvailable(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val networkCapabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        
        return networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
               networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)
    }
    
    private fun scheduleNextSync() {
        val syncRequest = PeriodicWorkRequestBuilder<DataSyncWorker>(15, TimeUnit.MINUTES)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .setRequiresBatteryNotLow(true)
                    .build()
            )
            .build()
        
        WorkManager.getInstance(applicationContext)
            .enqueueUniquePeriodicWork(
                "data_sync",
                ExistingPeriodicWorkPolicy.KEEP,
                syncRequest
            )
    }
}
```

### BLE Connection Monitor
```kotlin
// ble/worker/BleConnectionWorker.kt
@HiltWorker
class BleConnectionWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted workerParams: WorkerParameters,
    private val bleConnectionManager: BleConnectionManager,
    private val deviceRepository: DeviceRepository
) : CoroutineWorker(context, workerParams) {
    
    override suspend fun doWork(): Result {
        return try {
            // Get all registered devices
            val devices = deviceRepository.getRegisteredDevices()
            
            devices.forEach { device ->
                // Check connection status
                val connection = bleConnectionManager.getConnection(device.address)
                
                if (connection == null || !connection.isConnected()) {
                    // Attempt to reconnect
                    bleConnectionManager.connectToDevice(device.bluetoothDevice)
                        .collect { state ->
                            when (state) {
                                is ConnectionState.Connected -> {
                                    Timber.d("Reconnected to device: ${device.address}")
                                }
                                is ConnectionState.Error -> {
                                    Timber.w("Failed to reconnect to device: ${device.address}")
                                }
                            }
                        }
                }
            }
            
            Result.success()
        } catch (e: Exception) {
            Timber.e(e, "Error in BLE connection monitoring")
            Result.retry()
        }
    }
}
```

---

## 🎨 UI Layer (Jetpack Compose)

### Main Dashboard Screen
```kotlin
// presentation/ui/dashboard/DashboardScreen.kt
@Composable
fun DashboardScreen(
    viewModel: DashboardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    LaunchedEffect(Unit) {
        viewModel.loadDashboardData()
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Header
        DashboardHeader()
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Stats Cards
        when (val state = uiState) {
            is DashboardUiState.Loading -> {
                DashboardStatsLoading()
            }
            is DashboardUiState.Success -> {
                DashboardStats(stats = state.stats)
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Connected Devices
                ConnectedDevicesCard(devices = state.connectedDevices)
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Recent Alerts
                RecentAlertsCard(alerts = state.recentAlerts)
            }
            is DashboardUiState.Error -> {
                ErrorMessage(
                    message = state.message,
                    onRetry = { viewModel.loadDashboardData() }
                )
            }
        }
    }
}

@Composable
private fun DashboardStats(stats: DashboardStats) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        contentPadding = PaddingValues(horizontal = 4.dp)
    ) {
        item {
            StatCard(
                title = "Dispositivos Conectados",
                value = stats.connectedDevices.toString(),
                icon = Icons.Default.BluetoothConnected,
                color = MaterialTheme.colorScheme.primary
            )
        }
        
        item {
            StatCard(
                title = "Sessões Ativas",
                value = stats.activeSessions.toString(),
                icon = Icons.Default.PlayArrow,
                color = Color(0xFF4CAF50)
            )
        }
        
        item {
            StatCard(
                title = "Alertas Pendentes",
                value = stats.pendingAlerts.toString(),
                icon = Icons.Default.Warning,
                color = Color(0xFFFF9800)
            )
        }
        
        item {
            StatCard(
                title = "Dados Não Sincronizados",
                value = stats.unsyncedData.toString(),
                icon = Icons.Default.CloudOff,
                color = Color(0xFFF44336)
            )
        }
    }
}
```

### Device Connection Screen
```kotlin
// presentation/ui/devices/DeviceConnectionScreen.kt
@Composable
fun DeviceConnectionScreen(
    viewModel: DeviceConnectionViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val permissions = rememberMultiplePermissionsState(
        permissions = listOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
    )
    
    LaunchedEffect(permissions.allPermissionsGranted) {
        if (permissions.allPermissionsGranted) {
            viewModel.startScanning()
        }
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Header with scan button
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Dispositivos Disponíveis",
                style = MaterialTheme.typography.headlineSmall
            )
            
            Button(
                onClick = { 
                    if (permissions.allPermissionsGranted) {
                        viewModel.startScanning()
                    } else {
                        permissions.launchMultiplePermissionRequest()
                    }
                },
                enabled = uiState !is DeviceConnectionUiState.Scanning
            ) {
                if (uiState is DeviceConnectionUiState.Scanning) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Icon(Icons.Default.Search, contentDescription = null)
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(if (uiState is DeviceConnectionUiState.Scanning) "Buscando..." else "Buscar")
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Device list
        when (val state = uiState) {
            is DeviceConnectionUiState.Success -> {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(state.devices) { device ->
                        DeviceCard(
                            device = device,
                            onConnect = { viewModel.connectToDevice(device) }
                        )
                    }
                }
            }
            is DeviceConnectionUiState.Error -> {
                ErrorMessage(
                    message = state.message,
                    onRetry = { viewModel.startScanning() }
                )
            }
            else -> {
                // Loading or scanning state
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        CircularProgressIndicator()
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = when (state) {
                                is DeviceConnectionUiState.Scanning -> "Procurando dispositivos..."
                                else -> "Carregando..."
                            },
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }
        }
    }
}
```

---

## 🔐 Security Implementation

### Data Encryption
```kotlin
// security/EncryptionManager.kt
@Singleton
class EncryptionManager @Inject constructor(
    private val context: Context
) {
    
    companion object {
        private const val KEY_ALIAS = "orthotrack_master_key"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
    }
    
    private val masterKey: SecretKey by lazy {
        generateOrGetMasterKey()
    }
    
    private fun generateOrGetMasterKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
        keyStore.load(null)
        
        return if (keyStore.containsAlias(KEY_ALIAS)) {
            keyStore.getKey(KEY_ALIAS, null) as SecretKey
        } else {
            generateMasterKey()
        }
    }
    
    private fun generateMasterKey(): SecretKey {
        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        val keyGenParameterSpec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
        .setUserAuthenticationRequired(false)
        .build()
        
        keyGenerator.init(keyGenParameterSpec)
        return keyGenerator.generateKey()
    }
    
    fun encrypt(data: String): EncryptedData {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, masterKey)
        
        val iv = cipher.iv
        val encryptedBytes = cipher.doFinal(data.toByteArray(Charsets.UTF_8))
        
        return EncryptedData(
            encryptedData = Base64.encodeToString(encryptedBytes, Base64.DEFAULT),
            iv = Base64.encodeToString(iv, Base64.DEFAULT)
        )
    }
    
    fun decrypt(encryptedData: EncryptedData): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        val spec = GCMParameterSpec(128, Base64.decode(encryptedData.iv, Base64.DEFAULT))
        cipher.init(Cipher.DECRYPT_MODE, masterKey, spec)
        
        val decryptedBytes = cipher.doFinal(Base64.decode(encryptedData.encryptedData, Base64.DEFAULT))
        return String(decryptedBytes, Charsets.UTF_8)
    }
}

data class EncryptedData(
    val encryptedData: String,
    val iv: String
)
```

### API Security
```kotlin
// security/ApiKeyInterceptor.kt
class ApiKeyInterceptor @Inject constructor(
    private val tokenManager: TokenManager
) : Interceptor {
    
    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        
        val token = tokenManager.getAccessToken()
        
        val authenticatedRequest = originalRequest.newBuilder()
            .addHeader("Authorization", "Bearer $token")
            .addHeader("X-API-Version", "v1")
            .addHeader("X-Client-Type", "android")
            .build()
        
        val response = chain.proceed(authenticatedRequest)
        
        // Handle token refresh
        if (response.code == 401) {
            response.close()
            
            val refreshResult = tokenManager.refreshToken()
            
            if (refreshResult.isSuccess) {
                val newToken = refreshResult.getOrNull()
                val newRequest = originalRequest.newBuilder()
                    .addHeader("Authorization", "Bearer $newToken")
                    .build()
                
                return chain.proceed(newRequest)
            }
        }
        
        return response
    }
}
```

---

## 🧪 Testing Strategy

### Unit Tests
```kotlin
// BleConnectionManagerTest.kt
@ExperimentalCoroutinesApi
class BleConnectionManagerTest {
    
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()
    
    @Mock
    private lateinit var context: Context
    
    @Mock
    private lateinit var bluetoothDevice: BluetoothDevice
    
    @Mock
    private lateinit var dataProcessor: BleDataProcessor
    
    private lateinit var connectionManager: BleConnectionManager
    
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        connectionManager = BleConnectionManager(context, dataProcessor)
    }
    
    @Test
    fun `connectToDevice should emit Connected state on successful connection`() = runTest {
        // Given
        `when`(bluetoothDevice.address).thenReturn("AA:BB:CC:DD:EE:FF")
        
        // When
        val states = mutableListOf<ConnectionState>()
        connectionManager.connectToDevice(bluetoothDevice)
            .take(2)
            .collect { states.add(it) }
        
        // Then
        assertThat(states[0]).isInstanceOf(ConnectionState.Connecting::class.java)
        // Note: Full BLE testing requires more complex setup with mock BluetoothGatt
    }
}
```

### Integration Tests
```kotlin
// DatabaseTest.kt
@RunWith(AndroidJUnit4::class)
class DatabaseTest {
    
    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()
    
    private lateinit var database: OrthoTrackDatabase
    private lateinit var sensorReadingDao: SensorReadingDao
    
    @Before
    fun createDb() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        database = Room.inMemoryDatabaseBuilder(context, OrthoTrackDatabase::class.java)
            .allowMainThreadQueries()
            .build()
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
            gyroX = 0.1f,
            gyroY = 0.2f,
            gyroZ = 0.3f,
            temperature = 25.0f,
            humidity = 60.0f,
            pressurePoints = listOf(100f, 200f, 150f, 180f),
            batteryVoltage = 3.7f,
            isWearing = true,
            movementLevel = "medium",
            postureScore = 85.0f,
            comfortLevel = "comfortable"
        )
        
        // When
        val id = sensorReadingDao.insertReading(reading)
        val retrieved = sensorReadingDao.getReadingById(id)
        
        // Then
        assertThat(retrieved).isNotNull()
        assertThat(retrieved?.braceId).isEqualTo("test-brace")
        assertThat(retrieved?.accelX).isEqualTo(1.0f)
    }
}
```

---

## 📱 Build Configuration

### App-level Gradle
```kotlin
// app/build.gradle
android {
    namespace = "com.orthotrack.edgenode"
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.orthotrack.edgenode"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        
        testInstrumentationRunner = "com.orthotrack.edgenode.HiltTestRunner"
    }
    
    buildTypes {
        debug {
            isDebuggable = true
            applicationIdSuffix = ".debug"
            buildConfigField("String", "API_BASE_URL", "\"http://10.0.2.2:8080/api/v1\"")
            buildConfigField("String", "WS_URL", "\"ws://10.0.2.2:8080/ws\"")
        }
        
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            buildConfigField("String", "API_BASE_URL", "\"https://api.orthotrack.com/v1\"")
            buildConfigField("String", "WS_URL", "\"wss://api.orthotrack.com/ws\"")
        }
    }
    
    buildFeatures {
        compose = true
        buildConfig = true
    }
    
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.4"
    }
}

dependencies {
    // Core Android
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.0")
    
    // Compose
    implementation(platform("androidx.compose:compose-bom:2023.10.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.navigation:navigation-compose:2.7.4")
    
    // Hilt
    implementation("com.google.dagger:hilt-android:2.48")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")
    implementation("androidx.hilt:hilt-work:1.1.0")
    kapt("com.google.dagger:hilt-compiler:2.48")
    kapt("androidx.hilt:hilt-compiler:1.1.0")
    
    // Room
    implementation("androidx.room:room-runtime:2.6.0")
    implementation("androidx.room:room-ktx:2.6.0")
    kapt("androidx.room:room-compiler:2.6.0")
    
    // Network
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.11.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.11.0")
    
    // WorkManager
    implementation("androidx.work:work-runtime-ktx:2.8.1")
    
    // Permissions
    implementation("com.google.accompanist:accompanist-permissions:0.32.0")
    
    // Logging
    implementation("com.jakewharton.timber:timber:5.0.1")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.5.0")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    testImplementation("com.google.truth:truth:1.1.4")
    
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    androidTestImplementation("com.google.dagger:hilt-android-testing:2.48")
    kaptAndroidTest("com.google.dagger:hilt-compiler:2.48")
}
```

---

**Documentação Técnica - Android Edge Node**  
**Versão**: 1.0  
**Última Atualização**: 2024-12-03