# Implementation Plan - Sistema de Monitoramento em Tempo Real

- [x] 1. Setup WebSocket infrastructure




- [x] 1.1 Install Go WebSocket library (gorilla/websocket) and Redis client


  - Add dependencies to go.mod
  - _Requirements: All_

- [x] 1.2 Create WebSocket server structure with connection management


  - Implement WSServer struct with client registry
  - Implement Client struct with connection and subscriptions
  - Create message broadcasting channel
  - _Requirements: 1.1, 4.1_

- [x] 1.3 Implement WebSocket upgrade handler


  - Create HTTP endpoint /ws for WebSocket connections
  - Implement connection upgrade logic
  - _Requirements: 1.1_

- [x] 1.4 Write property test for connection management






















  - **Property 1: Device status event propagation**
  - **Validates: Requirements 1.1**


- [x] 2. Implement authentication and authorization





- [x] 2.1 Create JWT validation middleware for WebSocket connections


  - Extract and validate JWT from query parameter or header
  - Reject invalid/expired tokens with appropriate error codes
  - Store user ID in Client struct
  - _Requirements: 9.1, 9.2_

- [x] 2.2 Implement channel authorization logic


  - Create permission checker for different channel types
  - Verify user can access patient/device/dashboard channels
  - _Requirements: 9.3, 9.4_

- [x] 2.3 Handle token expiration during active connections


  - Periodically check token expiration
  - Close connection and send reauthentication request
  - _Requirements: 9.5_

- [x] 2.4 Write property test for JWT authentication


  - **Property 28: JWT authentication**
  - **Validates: Requirements 9.1, 9.2**

- [x] 2.5 Write property test for channel authorization



  - **Property 29: Channel authorization**
  - **Validates: Requirements 9.3, 9.4**

- [x] 3. Implement subscription management





- [x] 3.1 Create subscription handler for clients

  - Implement Subscribe() and Unsubscribe() methods
  - Maintain subscription map per client
  - Validate channel format and permissions
  - _Requirements: 5.1, 5.2_

- [x] 3.2 Implement viewer count tracking






  - Track number of subscribers per channel
  - Broadcast viewer count changes
  - Include viewer names in events
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 3.3 Create automatic subscription cleanup on disconnect


  - Remove all subscriptions when client disconnects
  - Update viewer counts
  - _Requirements: 5.2_

- [x] 3.4 Write property test for subscription management


  - **Property 18: Page navigation subscription**
  - **Validates: Requirements 5.1, 5.2, 5.5**

- [x] 3.5 Write property test for viewer count tracking

  - **Property 25: Viewer count tracking**
  - **Validates: Requirements 8.1, 8.2, 8.3**

- [x] 4. Implement Redis Pub/Sub integration





- [x] 4.1 Create Redis client and connection management


  - Initialize Redis client with connection pooling
  - Implement reconnection logic for Redis
  - _Requirements: 10.1_

- [x] 4.2 Implement event publishing to Redis


  - Create PublishEvent() function
  - Add metadata to prevent loops (instance ID, timestamp)
  - Serialize events to JSON
  - _Requirements: 10.1, 10.5_

- [x] 4.3 Implement Redis subscription handler


  - Subscribe to relevant Redis channels
  - Deserialize incoming events
  - Check metadata to prevent loops
  - Broadcast to WebSocket clients
  - _Requirements: 10.1, 10.2_

- [x] 4.4 Create event routing logic


  - Route events to correct WebSocket clients based on subscriptions
  - Handle multiple server instances
  - _Requirements: 10.2, 10.3_

- [x] 4.5 Write property test for Redis synchronization


































  - **Property 31: Redis Pub/Sub synchronization**
  - **Validates: Requirements 10.1, 10.2**

- [x] 4.6 Write property test for loop prevention


  - **Property 34: Loop prevention**
  - **Validates: Requirements 10.5**

- [x] 5. Implement heartbeat and connection health




- [x] 5.1 Create heartbeat sender in server


  - Send heartbeat message every 30 seconds to all clients
  - Include timestamp in heartbeat
  - _Requirements: 7.1, 7.5_

- [x] 5.2 Implement pong response handler


  - Track last pong time per client
  - Update Client.lastPong on pong received
  - _Requirements: 7.2_

- [x] 5.3 Create dead connection detector


  - Check for clients that haven't ponged in 90 seconds (3 heartbeats)
  - Close dead connections
  - _Requirements: 7.3_

- [x] 5.4 Write property test for heartbeat interval


  - **Property 20: Heartbeat interval**
  - **Validates: Requirements 7.1**

- [x] 5.5 Write property test for dead connection detection



  - **Property 22: Dead connection detection**
  - **Validates: Requirements 7.3**

- [x] 6. Implement event types and handlers





- [x] 6.1 Create device status event handler


  - Define DeviceStatusEvent struct
  - Publish to Redis when device status changes
  - Route to device:{id} channel subscribers
  - _Requirements: 1.1_

- [x] 6.2 Create alert event handler

  - Define AlertEvent struct
  - Publish to Redis when alert is created
  - Route to patient:{id} channel subscribers
  - _Requirements: 2.1_

- [x] 6.3 Create telemetry event handler

  - Define TelemetryEvent struct
  - Publish to Redis when telemetry received
  - Route to device:{id} channel subscribers
  - _Requirements: 3.1_

- [x] 6.4 Create usage session event handler

  - Define UsageSessionEvent struct (start/end)
  - Include duration in end events
  - Route to patient:{id} channel subscribers
  - _Requirements: 11.1, 11.2_

- [x] 6.5 Create dashboard statistics event handler

  - Define DashboardStatsEvent struct
  - Publish when statistics change
  - Route to dashboard channel subscribers
  - _Requirements: 6.1_

- [x] 6.6 Write property test for event propagation


  - **Property 9: Telemetry event propagation**
  - **Validates: Requirements 3.1**

- [x] 7. Integrate WebSocket with existing API endpoints





- [x] 7.1 Modify device status endpoint to publish WebSocket events


  - Add WebSocket event publishing to POST /api/v1/devices/status
  - Publish device status changes
  - _Requirements: 1.1_

- [x] 7.2 Modify alert creation endpoint to publish WebSocket events


  - Add WebSocket event publishing to POST /api/v1/devices/alerts
  - Publish new alerts
  - _Requirements: 2.1_


- [x] 7.3 Modify telemetry endpoint to publish WebSocket events

  - Add WebSocket event publishing to POST /api/v1/devices/telemetry
  - Publish telemetry data
  - _Requirements: 3.1_

- [x] 7.4 Create usage session tracking in backend


  - Detect session start/end from telemetry
  - Calculate session duration
  - Publish usage session events
  - _Requirements: 11.1, 11.2_

- [x] 7.5 Create dashboard statistics calculator


  - Recalculate stats when data changes
  - Publish dashboard statistics events
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 8. Implement logging and metrics





- [x] 8.1 Create connection lifecycle logger


  - Log connection established (user ID, IP, timestamp)
  - Log connection closed (reason, duration)
  - _Requirements: 12.1, 12.2_

- [x] 8.2 Create event logger

  - Log events sent (type, channel, recipient count)
  - _Requirements: 12.3_

- [x] 8.3 Create error logger

  - Log connection errors with stack traces
  - _Requirements: 12.4_

- [x] 8.4 Implement metrics collection


  - Track active connections
  - Track events per second
  - Track average latency
  - Expose metrics endpoint
  - _Requirements: 12.5_

- [x] 8.5 Write property test for logging


  - **Property 39: Connection logging**
  - **Validates: Requirements 12.1, 12.2**

- [x] 9. Checkpoint - Ensure backend tests pass




  - Ensure all tests pass, ask the user if questions arise.

- [-] 10. Create frontend WebSocket client



- [x] 10.1 Install WebSocket dependencies


  - No additional dependencies needed (native WebSocket API)
  - Install fast-check for property testing
  - _Requirements: All_

- [x] 10.2 Create WebSocketClient class


  - Implement connection management
  - Implement message sending/receiving
  - Store subscriptions
  - Implement event handler registry
  - _Requirements: 1.1, 4.1_

- [x] 10.3 Implement reconnection logic with exponential backoff

  - Start with 1 second delay
  - Double delay on each failure
  - Cap at 30 seconds
  - Reset on successful connection
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 10.4 Implement subscription restoration after reconnect

  - Store active subscriptions
  - Resubscribe to all channels after reconnect
  - _Requirements: 4.4_

- [x] 10.5 Implement heartbeat/pong handler

  - Listen for heartbeat messages
  - Respond with pong
  - Track last heartbeat time
  - Initiate reconnect if no heartbeat for 60s
  - _Requirements: 7.2, 7.4_

- [x] 10.6 Write property test for reconnection backoff


  - **Property 14: Exponential backoff**
  - **Validates: Requirements 4.2, 4.3**

- [x] 10.7 Write property test for subscription restoration







  - **Property 15: Subscription restoration**
  - **Validates: Requirements 4.4**

- [x] 11. Create Svelte stores for real-time data





- [x] 11.1 Create deviceStatuses store


  - Writable store with Map<string, DeviceStatus>
  - Update on device status events
  - _Requirements: 1.1, 1.2_

- [x] 11.2 Create telemetryData store


  - Writable store with Map<string, TelemetryPoint[]>
  - Implement 100-point buffer per device
  - Update on telemetry events
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 11.3 Create activeAlerts store


  - Writable store with Alert[]
  - Add alerts on alert events
  - _Requirements: 2.1_

- [x] 11.4 Create dashboardStats store


  - Writable store with DashboardStats
  - Update on dashboard statistics events
  - _Requirements: 6.1_

- [x] 11.5 Create viewerCounts store


  - Writable store with Map<string, number>
  - Update on viewer count events
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 11.6 Write property test for chart buffer limit


  - **Property 11: Chart buffer limit**
  - **Validates: Requirements 3.3**

- [x] 12. Implement toast notification system





- [x] 12.1 Create ToastNotification component


  - Display severity, message, patient name
  - Position in top-right corner
  - Support click to navigate
  - _Requirements: 2.2, 2.3, 2.5_

- [x] 12.2 Create toast store and manager


  - Add toast on alert events
  - Auto-remove after 10 seconds
  - Handle click navigation
  - _Requirements: 2.2, 2.6_


- [x] 12.3 Implement audio notification

  - Play sound on toast display if enabled
  - Check user audio settings
  - _Requirements: 2.4_

- [x] 12.4 Write property test for toast auto-removal


  - **Property 8: Toast auto-removal**
  - **Validates: Requirements 2.6**


- [x] 13. Create UI components for real-time updates





- [x] 13.1 Create DeviceStatusBadge component


  - Render badge based on status (online/offline/maintenance)
  - Show correct color and text
  - Display timestamp
  - _Requirements: 1.3, 1.4, 1.5_

- [x] 13.2 Update device list page with real-time status


  - Subscribe to device status channels
  - Update badges without reload
  - _Requirements: 1.2, 5.4_

- [x] 13.3 Create real-time telemetry charts


  - Use Chart.js or similar library
  - Update charts on telemetry events
  - Implement 100-point sliding window
  - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 13.4 Update patient details page with real-time data


  - Subscribe to patient channel on mount
  - Unsubscribe on unmount
  - Display usage indicator
  - Update compliance in real-time
  - _Requirements: 5.1, 5.2, 11.3, 11.4, 11.5_

- [x] 13.5 Create viewer count indicator


  - Display eye icon when viewers > 1
  - Show tooltip with viewer names on hover
  - _Requirements: 8.4, 8.5_

- [x] 13.6 Update dashboard with real-time statistics


  - Subscribe to dashboard channel
  - Update counters without reload
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 14. Implement reconnection UI feedback





- [x] 14.1 Create reconnection indicator component


  - Display "Reconnecting..." banner at top
  - Show during reconnection attempts
  - _Requirements: 4.5_

- [x] 14.2 Create reconnection success message


  - Display success message for 3 seconds
  - Remove indicator on success
  - _Requirements: 4.6_

- [x] 14.3 Write property test for UI updates without reload


  - **Property 2: UI updates without page reload**
  - **Validates: Requirements 1.2**

- [x] 15. Integrate WebSocket client with application





- [x] 15.1 Create WebSocket service singleton


  - Initialize on app mount
  - Connect with JWT token
  - Make available globally
  - _Requirements: All_

- [x] 15.2 Implement automatic subscription management


  - Subscribe/unsubscribe based on current route
  - Handle navigation between pages
  - _Requirements: 5.1, 5.2, 5.5_

- [x] 15.3 Handle authentication errors



  - Redirect to login on 401
  - Show error message
  - _Requirements: 9.1, 9.2_

- [x] 16. Add environment configuration





- [x] 16.1 Configure WebSocket URL for development


  - Use ws://192.168.43.205:8080/ws for local development
  - _Requirements: All_

- [x] 16.2 Configure WebSocket URL for production


  - Use wss://api.orthotrack.com/ws for production
  - _Requirements: All_

- [x] 16.3 Add Redis configuration


  - Configure Redis connection string
  - Set connection pool size
  - _Requirements: 10.1_

- [x] 17. Final checkpoint - Ensure all tests pass











  - Ensure all tests pass, ask the user if questions arise.
