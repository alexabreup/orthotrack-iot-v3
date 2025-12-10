# Design Document - Sistema de Monitoramento em Tempo Real

## Overview

O Sistema de Monitoramento em Tempo Real utiliza WebSocket para fornecer atualizações instantâneas sobre dispositivos, telemetria e alertas. A arquitetura é projetada para ser escalável horizontalmente usando Redis Pub/Sub, resiliente com reconexão automática, e segura com autenticação JWT.

## Architecture

### High-Level Architecture

```
┌─────────────┐         WebSocket          ┌──────────────────┐
│   Browser   │◄──────────────────────────►│  WebSocket       │
│   Client    │         (WSS/WS)           │  Server (Go)     │
└─────────────┘                            └──────────────────┘
                                                    │
                                                    │ Pub/Sub
                                                    ▼
                                            ┌──────────────────┐
                                            │  Redis Pub/Sub   │
                                            └──────────────────┘
                                                    ▲
                                                    │
                                            ┌──────────────────┐
                                            │  Backend API     │
                                            │  (Go + Gin)      │
                                            └──────────────────┘
                                                    │
                                                    ▼
                                            ┌──────────────────┐
                                            │  PostgreSQL      │
                                            └──────────────────┘
```

### Component Interaction Flow

1. **Client Connection**: Browser estabelece conexão WebSocket com autenticação JWT
2. **Subscription Management**: Cliente subscreve a canais específicos (patient:123, device:456, dashboard)
3. **Event Publishing**: Backend API publica eventos no Redis quando dados mudam
4. **Event Broadcasting**: WebSocket server recebe eventos do Redis e envia para clientes subscritos
5. **Heartbeat**: Servidor envia ping a cada 30s, cliente responde com pong
6. **Reconnection**: Cliente detecta desconexão e reconecta com backoff exponencial

## Components and Interfaces

### Backend Components

#### 1. WebSocket Server (Go)

**Responsibilities:**
- Gerenciar conexões WebSocket
- Autenticar clientes via JWT
- Gerenciar subscrições de canais
- Enviar/receber mensagens
- Implementar heartbeat/pong
- Logging e métricas

**Key Structures:**
```go
type WSServer struct {
    clients    map[*Client]bool
    broadcast  chan *Message
    register   chan *Client
    unregister chan *Client
    redis      *redis.Client
}

type Client struct {
    id            string
    conn          *websocket.Conn
    send          chan []byte
    subscriptions map[string]bool
    userID        string
    lastPong      time.Time
}

type Message struct {
    Type      string      `json:"type"`
    Channel   string      `json:"channel"`
    Data      interface{} `json:"data"`
    Timestamp int64       `json:"timestamp"`
}
```

#### 2. Redis Pub/Sub Manager

**Responsibilities:**
- Subscrever a canais Redis
- Publicar eventos para Redis
- Evitar loops de propagação
- Sincronizar entre instâncias

**Key Functions:**
```go
func (s *WSServer) PublishEvent(channel string, data interface{}) error
func (s *WSServer) SubscribeToRedis(channels ...string) error
func (s *WSServer) HandleRedisMessage(msg *redis.Message)
```

#### 3. Subscription Manager

**Responsibilities:**
- Gerenciar subscrições de clientes
- Verificar permissões de acesso
- Manter contadores de visualizadores
- Limpar subscrições ao desconectar

**Key Functions:**
```go
func (c *Client) Subscribe(channel string) error
func (c *Client) Unsubscribe(channel string) error
func (s *WSServer) GetViewerCount(channel string) int
func (s *WSServer) GetViewers(channel string) []string
```

### Frontend Components

#### 1. WebSocket Client (TypeScript)

**Responsibilities:**
- Estabelecer conexão WebSocket
- Gerenciar reconexão com backoff exponencial
- Enviar/receber mensagens
- Responder a heartbeats
- Gerenciar subscrições

**Key Class:**
```typescript
class WebSocketClient {
  private ws: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectDelay = 30000;
  private subscriptions: Set<string> = new Set();
  private eventHandlers: Map<string, Function[]> = new Map();
  
  connect(token: string): void
  disconnect(): void
  subscribe(channel: string): void
  unsubscribe(channel: string): void
  on(eventType: string, handler: Function): void
  private handleReconnect(): void
  private sendPong(): void
}
```

#### 2. Event Handlers (Svelte Stores)

**Responsibilities:**
- Processar eventos WebSocket
- Atualizar stores reativos
- Exibir notificações toast
- Atualizar gráficos em tempo real

**Key Stores:**
```typescript
// Device status updates
export const deviceStatuses = writable<Map<string, DeviceStatus>>(new Map());

// Real-time telemetry
export const telemetryData = writable<Map<string, TelemetryPoint[]>>(new Map());

// Active alerts
export const activeAlerts = writable<Alert[]>([]);

// Dashboard statistics
export const dashboardStats = writable<DashboardStats>({
  activePatients: 0,
  onlineDevices: 0,
  activeAlerts: 0,
  averageCompliance: 0
});

// Viewer counts
export const viewerCounts = writable<Map<string, number>>(new Map());
```

#### 3. Toast Notification System

**Responsibilities:**
- Exibir notificações de alertas
- Auto-remover após timeout
- Permitir navegação ao clicar
- Reproduzir sons (se habilitado)

**Component:**
```typescript
interface ToastNotification {
  id: string;
  severity: 'info' | 'warning' | 'critical';
  message: string;
  patientName: string;
  patientId: string;
  timestamp: number;
  autoRemoveDelay: number; // 10000ms
}
```

## Data Models

### WebSocket Message Types

```typescript
// Device status change
interface DeviceStatusEvent {
  type: 'device_status';
  channel: string; // 'device:123'
  data: {
    device_id: string;
    status: 'online' | 'offline' | 'maintenance';
    timestamp: number;
    battery_level?: number;
  };
}

// New alert
interface AlertEvent {
  type: 'alert_created';
  channel: string; // 'patient:456'
  data: {
    alert_id: string;
    patient_id: string;
    patient_name: string;
    severity: 'info' | 'warning' | 'critical';
    message: string;
    timestamp: number;
  };
}

// Telemetry data
interface TelemetryEvent {
  type: 'telemetry';
  channel: string; // 'device:123'
  data: {
    device_id: string;
    timestamp: number;
    sensors: {
      temperature?: number;
      battery_level?: number;
      accelerometer?: { x: number; y: number; z: number };
    };
  };
}

// Usage session
interface UsageSessionEvent {
  type: 'usage_session_start' | 'usage_session_end';
  channel: string; // 'patient:456'
  data: {
    session_id: string;
    patient_id: string;
    device_id: string;
    timestamp: number;
    duration?: number; // only for end event
  };
}

// Dashboard statistics
interface DashboardStatsEvent {
  type: 'dashboard_stats';
  channel: 'dashboard';
  data: {
    active_patients: number;
    online_devices: number;
    active_alerts: number;
    average_compliance: number;
    timestamp: number;
  };
}

// Viewer count
interface ViewerCountEvent {
  type: 'viewer_count';
  channel: string; // 'patient:456'
  data: {
    count: number;
    viewers: string[]; // user names
  };
}

// Heartbeat
interface HeartbeatEvent {
  type: 'heartbeat';
  data: {
    timestamp: number;
  };
}

// Pong response
interface PongEvent {
  type: 'pong';
  data: {
    timestamp: number;
  };
}
```

### Subscription Channels

```
- device:{device_id}        - Status e telemetria de dispositivo específico
- patient:{patient_id}      - Alertas e sessões de uso de paciente específico
- dashboard                 - Estatísticas gerais do dashboard institucional
- alerts:global             - Alertas críticos globais
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

Before listing the properties, I performed a reflection to eliminate redundancy:

**Redundancies Identified:**
- Properties 1.3, 1.4, 1.5 (badge rendering for different statuses) can be combined into one property about status badge rendering
- Properties 3.4, 3.5, 3.6 (telemetry updates for different sensor types) can be combined into one property about sensor data updates
- Properties 5.3, 5.4 (specific page subscriptions) are examples that don't need separate properties
- Properties 6.2, 6.3, 6.4 (counter updates) can be combined into one property about counter synchronization

**Final Property Set:**

### Property 1: Device status event propagation
*For any* device status change, the system should send a WebSocket event to all clients subscribed to that device's channel
**Validates: Requirements 1.1**

### Property 2: UI updates without page reload
*For any* WebSocket event received, the system should update the UI without triggering a page reload
**Validates: Requirements 1.2**

### Property 3: Status badge rendering
*For any* device status (online, offline, maintenance), the system should render the correct badge color, text, and timestamp
**Validates: Requirements 1.3, 1.4, 1.5**

### Property 4: Alert event propagation
*For any* critical alert created, the system should send a WebSocket event to all clients subscribed to the related patient's channel
**Validates: Requirements 2.1**

### Property 5: Toast notification display
*For any* alert event received, the system should display a toast notification in the top-right corner with severity, message, and patient name
**Validates: Requirements 2.2, 2.3**

### Property 6: Toast audio notification
*For any* toast notification, if audio is enabled in user settings, the system should play a notification sound
**Validates: Requirements 2.4**

### Property 7: Toast navigation
*For any* toast notification clicked, the system should navigate to the patient details page
**Validates: Requirements 2.5**

### Property 8: Toast auto-removal
*For any* toast notification, if not interacted with for 10 seconds, the system should automatically remove it
**Validates: Requirements 2.6**

### Property 9: Telemetry event propagation
*For any* telemetry data received by backend, the system should send a WebSocket event to clients subscribed to that device's channel
**Validates: Requirements 3.1**

### Property 10: Chart data addition
*For any* telemetry event received, the system should add the new data point to the corresponding chart
**Validates: Requirements 3.2**

### Property 11: Chart buffer limit
*For any* chart with 100 data points, adding a new point should remove the oldest point first
**Validates: Requirements 3.3**

### Property 12: Sensor data updates
*For any* telemetry event containing sensor data (temperature, battery, accelerometer), the system should update the corresponding UI element in real-time
**Validates: Requirements 3.4, 3.5, 3.6**

### Property 13: Initial reconnection timing
*For any* WebSocket disconnection, the system should attempt to reconnect after exactly 1 second
**Validates: Requirements 4.1**

### Property 14: Exponential backoff
*For any* failed reconnection attempt, the system should double the wait interval up to a maximum of 30 seconds
**Validates: Requirements 4.2, 4.3**

### Property 15: Subscription restoration
*For any* successful reconnection, the system should automatically resubscribe to all previously subscribed channels
**Validates: Requirements 4.4**

### Property 16: Reconnection UI indicator
*For any* reconnection attempt in progress, the system should display a "Reconnecting..." indicator at the top of the page
**Validates: Requirements 4.5**

### Property 17: Reconnection success feedback
*For any* successful reconnection, the system should remove the indicator and show a success message for 3 seconds
**Validates: Requirements 4.6**

### Property 18: Page navigation subscription
*For any* page navigation, the system should subscribe to appropriate channels and unsubscribe from previous channels
**Validates: Requirements 5.1, 5.2, 5.5**

### Property 19: Dashboard statistics synchronization
*For any* change in dashboard statistics (patients, devices, alerts, compliance), the system should send a WebSocket event and update all subscribed clients
**Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

### Property 20: Heartbeat interval
*For any* active WebSocket connection, the server should send a heartbeat message every 30 seconds
**Validates: Requirements 7.1**

### Property 21: Pong response
*For any* heartbeat received, the client should respond with a pong message
**Validates: Requirements 7.2**

### Property 22: Dead connection detection
*For any* connection that fails to respond to 3 consecutive heartbeats, the server should close the connection
**Validates: Requirements 7.3**

### Property 23: Client-side heartbeat timeout
*For any* client that doesn't receive a heartbeat for 60 seconds, the system should initiate reconnection
**Validates: Requirements 7.4**

### Property 24: Heartbeat timestamp
*For any* heartbeat message, the system should include a timestamp for clock synchronization
**Validates: Requirements 7.5**

### Property 25: Viewer count tracking
*For any* subscription or unsubscription to a patient channel, the system should update the viewer count and broadcast to all viewers
**Validates: Requirements 8.1, 8.2, 8.3**

### Property 26: Viewer count display
*For any* patient channel with more than 1 viewer, the system should display an eye icon with the viewer count
**Validates: Requirements 8.4**

### Property 27: Viewer tooltip
*For any* viewer count icon hover, the system should display a tooltip with names of other users viewing
**Validates: Requirements 8.5**

### Property 28: JWT authentication
*For any* WebSocket connection attempt, the system should validate the provided JWT token and reject invalid or expired tokens
**Validates: Requirements 9.1, 9.2**

### Property 29: Channel authorization
*For any* subscription attempt, the system should verify user permissions and reject unauthorized subscriptions
**Validates: Requirements 9.3, 9.4**

### Property 30: Token expiration handling
*For any* active connection with an expired JWT, the system should close the connection and request reauthentication
**Validates: Requirements 9.5**

### Property 31: Redis Pub/Sub synchronization
*For any* event published on one server instance, the system should propagate it to clients connected to other instances via Redis Pub/Sub
**Validates: Requirements 10.1, 10.2**

### Property 32: Load balancing
*For any* client connection, the system should be able to connect to any available server instance
**Validates: Requirements 10.3**

### Property 33: Failover handling
*For any* server instance failure, clients should be able to reconnect to another instance without losing functionality
**Validates: Requirements 10.4**

### Property 34: Loop prevention
*For any* event published via Redis, the system should include metadata to prevent propagation loops
**Validates: Requirements 10.5**

### Property 35: Usage session events
*For any* usage session start or end, the system should send a WebSocket event to clients subscribed to the patient's channel
**Validates: Requirements 11.1, 11.2**

### Property 36: Usage indicator display
*For any* usage session start event, the system should display an "In Use" indicator on the patient card
**Validates: Requirements 11.3**

### Property 37: Usage time tracking
*For any* usage session end event, the system should update the daily usage hours counter
**Validates: Requirements 11.4**

### Property 38: Compliance recalculation
*For any* usage session end event, the system should recalculate and update the daily compliance percentage in real-time
**Validates: Requirements 11.5**

### Property 39: Connection logging
*For any* WebSocket connection established or closed, the system should log user ID, IP, timestamp, reason, and duration
**Validates: Requirements 12.1, 12.2**

### Property 40: Event logging
*For any* event sent, the system should log event type, channel, and number of recipients
**Validates: Requirements 12.3**

### Property 41: Error logging
*For any* connection error, the system should log error details and stack trace
**Validates: Requirements 12.4**

### Property 42: Metrics collection
*For any* metrics collection interval, the system should include active connections, events per second, and average latency
**Validates: Requirements 12.5**

## Error Handling

### Connection Errors

1. **Authentication Failure**: Return 401 Unauthorized with error message
2. **Authorization Failure**: Send error message via WebSocket, don't close connection
3. **Invalid Message Format**: Log error, send error response to client
4. **Network Timeout**: Client initiates reconnection with backoff
5. **Server Overload**: Return 503 Service Unavailable, client retries

### Message Processing Errors

1. **Invalid Channel**: Send error message, don't process subscription
2. **Malformed JSON**: Log error, send error response
3. **Missing Required Fields**: Validate and return specific error
4. **Rate Limiting**: Throttle messages, send warning to client

### Redis Errors

1. **Connection Lost**: Log error, attempt reconnection, queue messages
2. **Publish Failure**: Retry with exponential backoff, log failure
3. **Subscribe Failure**: Retry subscription, alert monitoring

## Testing Strategy

### Unit Tests

- WebSocket connection establishment and closure
- Message serialization/deserialization
- Subscription management (add/remove)
- Heartbeat/pong protocol
- JWT validation
- Permission checking
- Reconnection logic
- Backoff calculation
- Toast notification lifecycle
- Chart data buffer management

### Property-Based Tests

The system will use **Rapid** (Go) for backend property tests and **fast-check** (TypeScript) for frontend property tests. Each property-based test should run a minimum of 100 iterations.

**Backend (Go + Rapid):**
- Event propagation to subscribed clients
- Redis Pub/Sub synchronization across instances
- Heartbeat timing and dead connection detection
- JWT expiration handling
- Viewer count accuracy
- Loop prevention in Redis events

**Frontend (TypeScript + fast-check):**
- Reconnection backoff timing
- Subscription restoration after reconnect
- Chart buffer limit enforcement
- Toast auto-removal timing
- UI updates without page reload

**Test Tagging Format:**
Each property-based test must be tagged with:
```
// Feature: realtime-monitoring, Property {number}: {property_text}
```

### Integration Tests

- End-to-end WebSocket communication
- Multi-instance server synchronization via Redis
- Client reconnection and subscription restoration
- Real-time UI updates from backend events
- Authentication and authorization flow

### Performance Tests

- Maximum concurrent connections per instance
- Message throughput (events per second)
- Latency from event publish to client receive
- Memory usage with many subscriptions
- Redis Pub/Sub performance under load

## Performance Targets

- **Connection Establishment**: < 100ms
- **Event Latency**: < 50ms from publish to client receive
- **Concurrent Connections**: 10,000+ per instance
- **Message Throughput**: 1,000+ events/second per instance
- **Reconnection Time**: < 2 seconds (first attempt)
- **Memory per Connection**: < 10KB

## Security Considerations

1. **Authentication**: JWT tokens validated on connection
2. **Authorization**: Channel access checked per subscription
3. **Rate Limiting**: Max 100 messages/second per client
4. **Input Validation**: All messages validated against schema
5. **TLS/SSL**: WSS (WebSocket Secure) in production
6. **CORS**: Restrict origins to known domains
7. **Token Refresh**: Handle token expiration gracefully

## Deployment Considerations

### Development
- WebSocket server: `ws://192.168.43.205:8080/ws`
- Redis: Local instance
- Single server instance

### Production
- WebSocket server: `wss://api.orthotrack.com/ws`
- Redis: Managed Redis cluster
- Multiple server instances behind load balancer
- Sticky sessions not required (stateless with Redis)

## Monitoring and Observability

### Metrics to Track
- Active WebSocket connections
- Events published per second
- Average event latency
- Reconnection rate
- Authentication failures
- Authorization failures
- Redis Pub/Sub lag
- Memory usage per connection

### Logging
- Connection lifecycle (connect, disconnect, duration)
- Authentication/authorization events
- Errors and exceptions
- Performance metrics
- Redis connectivity issues

### Alerts
- High reconnection rate (> 10% of connections)
- Authentication failure spike
- Redis connection loss
- High event latency (> 200ms)
- Memory usage threshold exceeded
