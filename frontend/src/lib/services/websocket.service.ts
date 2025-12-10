/**
 * WebSocket Client Service for Real-time Monitoring
 * Handles WebSocket connections, subscriptions, and event management
 */

export interface WebSocketMessage {
  type: string;
  channel?: string;
  data?: any;
  timestamp?: number;
}

export interface WebSocketEventHandler {
  (data: any): void;
}

export interface ConnectionOptions {
  token: string;
  url?: string;
}

export class WebSocketClient {
  private ws: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectDelay = 30000; // 30 seconds
  private baseReconnectDelay = 1000; // 1 second
  private currentReconnectDelay = this.baseReconnectDelay;
  private reconnectTimer: number | null = null;
  private heartbeatTimer: number | null = null;
  private lastHeartbeat = 0;
  private heartbeatTimeout = 60000; // 60 seconds
  
  private subscriptions: Set<string> = new Set();
  private eventHandlers: Map<string, WebSocketEventHandler[]> = new Map();
  private connectionOptions: ConnectionOptions | null = null;
  
  private isConnecting = false;
  private isConnected = false;
  private shouldReconnect = true;

  constructor() {
    // Bind methods to preserve 'this' context
    this.handleOpen = this.handleOpen.bind(this);
    this.handleMessage = this.handleMessage.bind(this);
    this.handleClose = this.handleClose.bind(this);
    this.handleError = this.handleError.bind(this);
  }

  /**
   * Connect to WebSocket server
   */
  connect(options: ConnectionOptions): void {
    if (this.isConnecting || this.isConnected) {
      return;
    }

    this.connectionOptions = options;
    this.isConnecting = true;
    this.shouldReconnect = true;

    const wsUrl = this.buildWebSocketUrl(options);
    
    try {
      this.ws = new WebSocket(wsUrl);
      this.ws.addEventListener('open', this.handleOpen);
      this.ws.addEventListener('message', this.handleMessage);
      this.ws.addEventListener('close', this.handleClose);
      this.ws.addEventListener('error', this.handleError);
    } catch (error) {
      console.error('Failed to create WebSocket connection:', error);
      this.isConnecting = false;
      this.scheduleReconnect();
    }
  }

  /**
   * Disconnect from WebSocket server
   */
  disconnect(): void {
    this.shouldReconnect = false;
    this.clearTimers();
    
    if (this.ws) {
      this.ws.removeEventListener('open', this.handleOpen);
      this.ws.removeEventListener('message', this.handleMessage);
      this.ws.removeEventListener('close', this.handleClose);
      this.ws.removeEventListener('error', this.handleError);
      
      if (this.ws.readyState === WebSocket.OPEN) {
        this.ws.close(1000, 'Client disconnect');
      }
      this.ws = null;
    }
    
    this.isConnected = false;
    this.isConnecting = false;
    this.reconnectAttempts = 0;
    this.currentReconnectDelay = this.baseReconnectDelay;
  }

  /**
   * Subscribe to a channel
   */
  subscribe(channel: string): void {
    this.subscriptions.add(channel);
    
    if (this.isConnected) {
      this.sendMessage({
        type: 'subscribe',
        channel: channel
      });
    }
  }

  /**
   * Unsubscribe from a channel
   */
  unsubscribe(channel: string): void {
    this.subscriptions.delete(channel);
    
    if (this.isConnected) {
      this.sendMessage({
        type: 'unsubscribe',
        channel: channel
      });
    }
  }

  /**
   * Register event handler
   */
  on(eventType: string, handler: WebSocketEventHandler): void {
    if (!this.eventHandlers.has(eventType)) {
      this.eventHandlers.set(eventType, []);
    }
    this.eventHandlers.get(eventType)!.push(handler);
  }

  /**
   * Remove event handler
   */
  off(eventType: string, handler: WebSocketEventHandler): void {
    const handlers = this.eventHandlers.get(eventType);
    if (handlers) {
      const index = handlers.indexOf(handler);
      if (index > -1) {
        handlers.splice(index, 1);
      }
    }
  }

  /**
   * Get connection status
   */
  getConnectionStatus(): 'connecting' | 'connected' | 'disconnected' | 'reconnecting' {
    if (this.isConnected) return 'connected';
    if (this.isConnecting) return 'connecting';
    if (this.reconnectTimer !== null) return 'reconnecting';
    return 'disconnected';
  }

  /**
   * Get current subscriptions
   */
  getSubscriptions(): string[] {
    return Array.from(this.subscriptions);
  }

  private buildWebSocketUrl(options: ConnectionOptions): string {
    const baseUrl = options.url || this.getDefaultWebSocketUrl();
    const url = new URL(baseUrl);
    url.searchParams.set('token', options.token);
    return url.toString();
  }

  private getDefaultWebSocketUrl(): string {
    // Determine WebSocket URL based on environment
    if (typeof window !== 'undefined') {
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const host = window.location.hostname;
      
      // Development environment
      if (host === 'localhost' || host === '127.0.0.1' || host.includes('192.168')) {
        return 'ws://192.168.43.205:8080/ws';
      }
      
      // Production environment
      return 'wss://api.orthotrack.com/ws';
    }
    
    // Fallback for server-side rendering
    return 'ws://192.168.43.205:8080/ws';
  }

  private handleOpen(): void {
    console.log('WebSocket connected');
    this.isConnected = true;
    this.isConnecting = false;
    this.reconnectAttempts = 0;
    this.currentReconnectDelay = this.baseReconnectDelay;
    
    // Start heartbeat monitoring
    this.startHeartbeatMonitoring();
    
    // Restore subscriptions
    this.restoreSubscriptions();
    
    // Emit connection event
    this.emitEvent('connected', {});
  }

  private handleMessage(event: MessageEvent): void {
    try {
      const message: WebSocketMessage = JSON.parse(event.data);
      
      // Handle heartbeat
      if (message.type === 'heartbeat') {
        this.handleHeartbeat(message);
        return;
      }
      
      // Update last heartbeat time for any message
      this.lastHeartbeat = Date.now();
      
      // Emit the message to registered handlers
      this.emitEvent(message.type, message.data || message);
      
    } catch (error) {
      console.error('Failed to parse WebSocket message:', error);
    }
  }

  private handleClose(event: CloseEvent): void {
    console.log('WebSocket disconnected:', event.code, event.reason);
    this.isConnected = false;
    this.isConnecting = false;
    this.clearTimers();
    
    // Emit disconnection event
    this.emitEvent('disconnected', { code: event.code, reason: event.reason });
    
    // Schedule reconnection if needed
    if (this.shouldReconnect && event.code !== 1000) {
      this.scheduleReconnect();
    }
  }

  private handleError(event: Event): void {
    console.error('WebSocket error:', event);
    this.emitEvent('error', { error: event });
  }

  private handleHeartbeat(message: WebSocketMessage): void {
    this.lastHeartbeat = Date.now();
    
    // Send pong response
    this.sendMessage({
      type: 'pong',
      data: {
        timestamp: Date.now()
      }
    });
  }

  private startHeartbeatMonitoring(): void {
    this.lastHeartbeat = Date.now();
    
    this.heartbeatTimer = window.setInterval(() => {
      const timeSinceLastHeartbeat = Date.now() - this.lastHeartbeat;
      
      if (timeSinceLastHeartbeat > this.heartbeatTimeout) {
        console.warn('Heartbeat timeout, initiating reconnection');
        this.handleHeartbeatTimeout();
      }
    }, 10000); // Check every 10 seconds
  }

  private handleHeartbeatTimeout(): void {
    this.clearTimers();
    
    if (this.ws) {
      this.ws.close(1001, 'Heartbeat timeout');
    }
  }

  private scheduleReconnect(): void {
    if (!this.shouldReconnect || this.reconnectTimer !== null) {
      return;
    }

    this.emitEvent('reconnecting', { 
      attempt: this.reconnectAttempts + 1, 
      delay: this.currentReconnectDelay 
    });

    this.reconnectTimer = window.setTimeout(() => {
      this.reconnectTimer = null;
      this.attemptReconnect();
    }, this.currentReconnectDelay);
  }

  private attemptReconnect(): void {
    if (!this.shouldReconnect || !this.connectionOptions) {
      return;
    }

    this.reconnectAttempts++;
    console.log(`Attempting to reconnect (attempt ${this.reconnectAttempts})`);
    
    // Increase delay for next attempt (exponential backoff)
    this.currentReconnectDelay = Math.min(
      this.currentReconnectDelay * 2,
      this.maxReconnectDelay
    );
    
    this.connect(this.connectionOptions);
  }

  private restoreSubscriptions(): void {
    // Resubscribe to all channels
    for (const channel of this.subscriptions) {
      this.sendMessage({
        type: 'subscribe',
        channel: channel
      });
    }
  }

  private sendMessage(message: WebSocketMessage): void {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      try {
        this.ws.send(JSON.stringify(message));
      } catch (error) {
        console.error('Failed to send WebSocket message:', error);
      }
    }
  }

  private emitEvent(eventType: string, data: any): void {
    const handlers = this.eventHandlers.get(eventType);
    if (handlers) {
      handlers.forEach(handler => {
        try {
          handler(data);
        } catch (error) {
          console.error(`Error in WebSocket event handler for ${eventType}:`, error);
        }
      });
    }
  }

  private clearTimers(): void {
    if (this.reconnectTimer !== null) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    
    if (this.heartbeatTimer !== null) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }
}

// Singleton instance
let websocketClient: WebSocketClient | null = null;

export function getWebSocketClient(): WebSocketClient {
  if (!websocketClient) {
    websocketClient = new WebSocketClient();
  }
  return websocketClient;
}