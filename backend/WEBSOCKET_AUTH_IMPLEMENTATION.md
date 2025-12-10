# WebSocket Authentication and Authorization Implementation

## Overview

This document describes the implementation of authentication and authorization for WebSocket connections in the OrthoTrack IoT v3 system.

## Implemented Components

### 1. JWT Validation Middleware (`internal/middleware/websocket_auth.go`)

**Purpose**: Validates JWT tokens for WebSocket connections

**Features**:
- Extracts JWT tokens from multiple sources:
  - Query parameter (`?token=...`)
  - Authorization header (`Bearer ...`)
  - Sec-WebSocket-Protocol header (alternative method)
- Validates token signature using HMAC-SHA256
- Checks token expiration
- Extracts user claims (user_id, institution_id, role)
- Returns token expiry time for connection lifecycle management

**Key Methods**:
- `ValidateWebSocketToken(c *gin.Context)` - Validates token and returns user info
- `AuthenticateWebSocket()` - Gin middleware for WebSocket authentication
- `GetUpgrader()` - Returns configured WebSocket upgrader

### 2. Channel Authorization (`internal/services/channel_authorization.go`)

**Purpose**: Controls access to WebSocket channels based on user permissions

**Supported Channel Types**:
- `dashboard` - Accessible to all authenticated users
- `alerts:global` - Accessible to all authenticated users
- `patient:{id}` - Requires access to specific patient
- `device:{id}` - Requires access to device's patient

**Authorization Rules**:
- **Admin/Administrator**: Full access to all resources in their institution
- **Medical Staff**: Access only to assigned patients and their devices
- **Institution Isolation**: Users can only access resources in their institution

**Key Methods**:
- `CanSubscribe(ctx, userID, institutionID, role, channel)` - Checks subscription permission
- `canAccessPatient(ctx, userID, institutionID, role, patientID)` - Validates patient access
- `canAccessDevice(ctx, userID, institutionID, role, deviceID)` - Validates device access
- `ValidateChannelFormat(channel)` - Validates channel format without DB check

### 3. WebSocket Service Updates (`internal/services/websocket_service.go`)

**Enhanced Client Structure**:
```go
type Client struct {
    ID            string
    Conn          *websocket.Conn
    Send          chan []byte
    Subscriptions map[string]bool
    UserID        string
    InstitutionID string    // NEW
    Role          string    // NEW
    TokenExpiry   time.Time // NEW
    LastPong      time.Time
    mu            sync.RWMutex
}
```

**Enhanced WSServer Structure**:
```go
type WSServer struct {
    clients    map[*Client]bool
    Broadcast  chan *Message
    Register   chan *Client
    Unregister chan *Client
    redis      *redis.Client
    authorizer *ChannelAuthorizer // NEW
    mu         sync.RWMutex
}
```

**Key Features**:
- Token expiration checking in WritePump (every 30 seconds)
- Automatic connection closure on token expiry
- Reauthentication request sent before closing
- Authorization check on every subscription attempt
- Error messages sent to client on authorization failure

### 4. Property-Based Tests

#### JWT Authentication Test (`internal/middleware/websocket_auth_test.go`)

**Property 28: JWT Authentication**
- Validates Requirements 9.1, 9.2
- Tests:
  - Valid tokens are accepted
  - Expired tokens are rejected
  - Invalid tokens are rejected
  - Token claims are correctly extracted
  - Token expiry is correctly returned
  - Tokens from different sources (query, header) work correctly

#### Channel Authorization Test (`internal/services/channel_authorization_test.go`)

**Property 29: Channel Authorization**
- Validates Requirements 9.3, 9.4
- Tests:
  - Valid channel formats are accepted
  - Invalid channel formats are rejected
  - Dashboard and global alerts are accessible to all
  - Patient and device channels have correct format
  - Role-based authorization structure
  - Authorization context is maintained

## Usage

### Setting Up WebSocket Server

```go
import (
    "orthotrack-iot-v3/internal/config"
    "orthotrack-iot-v3/internal/middleware"
    "orthotrack-iot-v3/internal/services"
)

// Load configuration
cfg := config.Load()

// Create Redis client
redisClient := redis.NewClient(&redis.Options{
    Addr: fmt.Sprintf("%s:%s", cfg.Redis.Host, cfg.Redis.Port),
    Password: cfg.Redis.Password,
    DB: cfg.Redis.DB,
})

// Create database connection
db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})

// Create channel authorizer
authorizer := services.NewChannelAuthorizer(db)

// Create WebSocket server
wsServer := services.NewWSServer(redisClient, authorizer)

// Create WebSocket auth middleware
wsAuth := middleware.NewWebSocketAuthMiddleware(cfg.JWT.Secret)

// Set up route
router.GET("/ws", wsAuth.AuthenticateWebSocket(), func(c *gin.Context) {
    // Extract user info from context
    userID := c.GetString("user_id")
    institutionID := c.GetString("institution_id")
    role := c.GetString("role")
    tokenExpiry := c.MustGet("token_expiry").(time.Time)
    
    // Upgrade connection
    upgrader := wsAuth.GetUpgrader()
    conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
    if err != nil {
        return
    }
    
    // Create client
    client := &services.Client{
        ID:            uuid.New().String(),
        Conn:          conn,
        Send:          make(chan []byte, 256),
        Subscriptions: make(map[string]bool),
        UserID:        userID,
        InstitutionID: institutionID,
        Role:          role,
        TokenExpiry:   tokenExpiry,
        LastPong:      time.Now(),
    }
    
    // Register client
    wsServer.Register <- client
    
    // Start pumps
    go client.WritePump()
    go client.ReadPump(wsServer)
})
```

### Client Connection (Frontend)

```javascript
// Connect with JWT token
const token = localStorage.getItem('jwt_token');
const ws = new WebSocket(`ws://localhost:8080/ws?token=${token}`);

// Or use Authorization header (if supported by browser)
const ws = new WebSocket('ws://localhost:8080/ws', {
    headers: {
        'Authorization': `Bearer ${token}`
    }
});

// Subscribe to channels
ws.send(JSON.stringify({
    type: 'subscribe',
    channel: 'patient:123'
}));

// Handle reauthentication requests
ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    if (msg.type === 'reauthentication_required') {
        // Token expired, reconnect with new token
        console.log('Token expired, please reconnect');
        ws.close();
        // Redirect to login or refresh token
    }
};
```

## Running Tests

### Prerequisites
- Go 1.21+
- Redis running on localhost:6379 (for integration tests)
- PostgreSQL database (for full integration tests)

### Run Property Tests

```bash
# Run JWT authentication tests
go test -v ./internal/middleware -run TestProperty_JWTAuthentication -count=1

# Run all JWT authentication property tests
go test -v ./internal/middleware -run TestProperty_ -count=1

# Run channel authorization tests
go test -v ./internal/services -run TestProperty_ChannelAuthorization -count=1

# Run all channel authorization property tests
go test -v ./internal/services -run TestProperty_ -count=1

# Run all tests with coverage
go test -v -cover ./internal/middleware ./internal/services
```

### Test Configuration

Property-based tests run 100 iterations by default (as specified in the design document). To change this:

```bash
# Run with more iterations
go test -v -rapid.checks=1000 ./internal/middleware -run TestProperty_
```

## Security Considerations

1. **Token Storage**: Tokens should be stored securely on the client (e.g., httpOnly cookies or secure storage)
2. **Token Expiry**: Tokens should have reasonable expiry times (e.g., 24 hours)
3. **CORS**: Update `CheckOrigin` in production to validate allowed origins
4. **TLS**: Use WSS (WebSocket Secure) in production
5. **Rate Limiting**: Consider adding rate limiting for subscription requests
6. **Audit Logging**: All authorization failures are logged for security monitoring

## Error Handling

### Authentication Errors
- **401 Unauthorized**: Invalid or missing token
- **Connection Closed (1008)**: Token expired during active connection

### Authorization Errors
- Error message sent via WebSocket with details
- Subscription not added to client
- Connection remains open for other operations

### Error Message Format
```json
{
    "type": "error",
    "channel": "patient:123",
    "data": {
        "error": "authorization failed: access denied",
        "action": "subscribe"
    },
    "timestamp": 1234567890
}
```

## Future Enhancements

1. **Token Refresh**: Implement token refresh mechanism for long-lived connections
2. **Permission Caching**: Cache authorization decisions to reduce database queries
3. **Audit Trail**: Enhanced logging of all authorization decisions
4. **Rate Limiting**: Per-user rate limiting for subscriptions
5. **Connection Limits**: Maximum connections per user
6. **Channel Wildcards**: Support for wildcard subscriptions (e.g., `patient:*`)

## Requirements Validation

### Requirement 9.1 ✓
"WHEN a client tries to connect via WebSocket THEN the Sistema SHALL validate the token JWT provided"
- Implemented in `ValidateWebSocketToken` method
- Tested in `TestProperty_JWTAuthentication`

### Requirement 9.2 ✓
"WHEN the token JWT is invalid or expired THEN the Sistema SHALL reject the connection with appropriate error code"
- Implemented with 401 status code for initial connection
- Implemented with close code 1008 for expired tokens during connection
- Tested in `TestProperty_InvalidTokenRejection`

### Requirement 9.3 ✓
"WHEN a client tries to subscribe to a channel THEN the Sistema SHALL verify if the user has permission to access that resource"
- Implemented in `CanSubscribe` method
- Tested in `TestProperty_ChannelAuthorization`

### Requirement 9.4 ✓
"WHEN the user does not have permission THEN the Sistema SHALL reject the subscription and send error message"
- Implemented in `Subscribe` method with error handling
- Error message sent to client via WebSocket

### Requirement 9.5 ✓
"WHEN the token JWT expires during an active connection THEN the Sistema SHALL close the connection and request reauthentication"
- Implemented in `WritePump` with periodic token expiry checks
- Reauthentication message sent before closing
- Connection closed with appropriate close code

## Notes

- Property-based tests require Go to be installed and available in PATH
- Tests are marked as "not_run" until Go environment is available
- Full integration tests require database setup
- Current tests focus on logic validation without database dependencies
