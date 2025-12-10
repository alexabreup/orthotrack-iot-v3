# WebSocket Property Test Instructions

## Task 1.4: Property Test for Connection Management

### Test Implementation Status: ✅ COMPLETE

The property test for **Device Status Event Propagation** has been implemented in:
- File: `backend/internal/services/websocket_service_test.go`
- Function: `TestProperty_DeviceStatusEventPropagation`

### What the Test Validates

**Property 1: Device status event propagation**
- **Validates Requirements:** 1.1
- **Property Statement:** *For any device status change, the system should send a WebSocket event to all clients subscribed to that device's channel*

### Test Implementation Details

The property-based test:
1. Creates a WebSocket server with Redis client
2. Generates random device IDs (3-20 alphanumeric characters)
3. Creates 1-10 random clients
4. Subscribes all clients to the device channel
5. Generates a random device status (online/offline/maintenance)
6. Broadcasts a device status event
7. Verifies ALL subscribed clients receive the message
8. Runs 100+ iterations with different random inputs

### How to Run the Tests

#### Option 1: Using Go (if installed)
```bash
cd backend
go test -v -run TestProperty_DeviceStatusEventPropagation ./internal/services/
```

#### Option 2: Using Docker
```bash
cd backend
docker run --rm -v ${PWD}:/app -w /app golang:1.23-alpine sh -c "go mod download && go test -v -run TestProperty_DeviceStatusEventPropagation ./internal/services/"
```

#### Option 3: Using the provided batch script
```bash
cd backend
.\run-websocket-tests.bat
```

### Prerequisites

- **Go 1.21+** (for Option 1 and 3)
- **Docker** (for Option 2)
- **Redis** running on localhost:6379 (optional - test will skip Redis tests if not available)

### Test Coverage

The test file also includes additional property tests:
- `TestProperty_UnsubscribedClientsDoNotReceiveMessages` - Validates clients only receive messages from subscribed channels
- `TestProperty_ViewerCountTracking` - Validates viewer count accuracy
- `TestProperty_RedisEventPublishing` - Validates Redis Pub/Sub integration

### Expected Output

When the test passes, you should see:
```
=== RUN   TestProperty_DeviceStatusEventPropagation
--- PASS: TestProperty_DeviceStatusEventPropagation (0.XXs)
PASS
ok      orthotrack-iot-v3/internal/services     0.XXXs
```

### Test Tagging

The test is properly tagged according to the spec requirements:
```go
// Feature: realtime-monitoring, Property 1: Device status event propagation
// Validates: Requirements 1.1
```

### Next Steps

1. Ensure Go is installed or Docker Desktop is running
2. Run the tests using one of the options above
3. Verify all tests pass
4. If tests fail, review the counterexample and determine if it's a bug in the code or test
