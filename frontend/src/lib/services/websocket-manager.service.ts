/**
 * WebSocket Manager Service - Singleton for managing WebSocket connections
 * Integrates with authentication and provides global access to WebSocket functionality
 */

import { getWebSocketClient, type WebSocketClient } from './websocket.service';
import { authService } from './auth.service';
import { addErrorToast, addInfoToast } from '$lib/stores/toast.store';
import { goto } from '$app/navigation';
import { writable } from 'svelte/store';

export interface WebSocketManagerState {
  status: 'disconnected' | 'connecting' | 'connected' | 'reconnecting' | 'error';
  error?: string;
  reconnectAttempt?: number;
}

class WebSocketManagerService {
  private client: WebSocketClient;
  private initialized = false;
  private currentToken: string | null = null;
  
  // Store for reactive state management
  public state = writable<WebSocketManagerState>({ status: 'disconnected' });

  constructor() {
    this.client = getWebSocketClient();
    this.setupEventHandlers();
  }

  /**
   * Initialize WebSocket connection with current authentication
   */
  async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    const token = authService.getToken();
    if (!token) {
      console.warn('No authentication token available for WebSocket connection');
      this.state.set({ status: 'error', error: 'No authentication token' });
      return;
    }

    this.currentToken = token;
    this.initialized = true;

    // Connect to WebSocket
    this.connect();
  }

  /**
   * Connect to WebSocket server
   */
  private connect(): void {
    if (!this.currentToken) {
      console.error('Cannot connect: No authentication token');
      this.state.set({ status: 'error', error: 'No authentication token' });
      return;
    }

    this.state.set({ status: 'connecting' });
    
    this.client.connect({
      token: this.currentToken
    });
  }

  /**
   * Disconnect from WebSocket server
   */
  disconnect(): void {
    this.client.disconnect();
    this.initialized = false;
    this.currentToken = null;
    this.state.set({ status: 'disconnected' });
  }

  /**
   * Reconnect with fresh token (useful after token refresh)
   */
  async reconnectWithNewToken(): Promise<void> {
    const token = authService.getToken();
    if (!token) {
      this.handleAuthenticationError();
      return;
    }

    // Disconnect current connection
    this.client.disconnect();
    
    // Update token and reconnect
    this.currentToken = token;
    this.connect();
  }

  /**
   * Subscribe to a channel
   */
  subscribe(channel: string): void {
    this.client.subscribe(channel);
  }

  /**
   * Unsubscribe from a channel
   */
  unsubscribe(channel: string): void {
    this.client.unsubscribe(channel);
  }

  /**
   * Register event handler
   */
  on(eventType: string, handler: (data: any) => void): void {
    this.client.on(eventType, handler);
  }

  /**
   * Remove event handler
   */
  off(eventType: string, handler: (data: any) => void): void {
    this.client.off(eventType, handler);
  }

  /**
   * Get current connection status
   */
  getConnectionStatus(): string {
    return this.client.getConnectionStatus();
  }

  /**
   * Get current subscriptions
   */
  getSubscriptions(): string[] {
    return this.client.getSubscriptions();
  }

  /**
   * Get the underlying WebSocket client (for advanced usage)
   */
  getClient(): WebSocketClient {
    return this.client;
  }

  /**
   * Setup event handlers for WebSocket events
   */
  private setupEventHandlers(): void {
    // Connection established
    this.client.on('connected', () => {
      console.log('WebSocket Manager: Connected');
      this.state.set({ status: 'connected' });
    });

    // Connection lost
    this.client.on('disconnected', (data: { code: number; reason: string }) => {
      console.log('WebSocket Manager: Disconnected', data);
      
      // Handle authentication errors (401 Unauthorized)
      // WebSocket close codes for authentication errors:
      // 1008 - Policy Violation (used for auth failures)
      // 4001 - Custom code for authentication failure
      // 4401 - Custom code mapping HTTP 401
      if (data.code === 1008 || data.code === 4001 || data.code === 4401) {
        this.handleAuthenticationError('WebSocket authentication failed');
      } else if (data.code === 1002) {
        // Protocol error - might indicate invalid token format
        this.handleAuthenticationError('Invalid authentication token format');
      } else {
        this.state.set({ status: 'disconnected' });
      }
    });

    // Reconnection attempts
    this.client.on('reconnecting', (data: { attempt: number; delay: number }) => {
      console.log(`WebSocket Manager: Reconnecting (attempt ${data.attempt})`);
      this.state.set({ 
        status: 'reconnecting', 
        reconnectAttempt: data.attempt 
      });
    });

    // Connection errors
    this.client.on('error', (data: { error: any }) => {
      console.error('WebSocket Manager: Error', data.error);
      
      // Check if error is related to authentication
      const errorMessage = data.error?.message || data.error?.toString() || 'Connection error';
      if (errorMessage.toLowerCase().includes('unauthorized') || 
          errorMessage.toLowerCase().includes('401') ||
          errorMessage.toLowerCase().includes('authentication')) {
        this.handleAuthenticationError('Authentication error during connection');
      } else {
        this.state.set({ 
          status: 'error', 
          error: errorMessage 
        });
      }
    });

    // Handle authentication-related messages from server
    this.client.on('auth_error', (data: { message: string; code?: number }) => {
      console.warn('WebSocket Manager: Authentication error from server', data);
      this.handleAuthenticationError(data.message || 'Server authentication error');
    });

    // Handle authorization errors (different from authentication)
    this.client.on('authorization_error', (data: { message: string; channel?: string }) => {
      console.warn('WebSocket Manager: Authorization error', data);
      // Don't redirect for authorization errors, just log them
      // These happen when user tries to access channels they don't have permission for
      this.state.set({ 
        status: 'error', 
        error: `Access denied: ${data.message}` 
      });
    });
  }

  /**
   * Handle authentication errors by redirecting to login
   */
  private handleAuthenticationError(message: string): void {
    console.warn('WebSocket authentication failed:', message);
    
    this.state.set({ 
      status: 'error', 
      error: message 
    });
    
    // Show error toast to user
    addErrorToast(`Authentication failed: ${message}. Please log in again.`, 5000);
    
    // Disconnect to prevent reconnection attempts with invalid token
    this.disconnect();
    
    // Clear authentication and redirect to login
    // Use setTimeout to ensure state updates are processed first
    setTimeout(() => {
      authService.logout();
      goto('/login');
    }, 100);
  }
}

// Singleton instance
let _websocketManager: WebSocketManagerService | null = null;

export function getWebSocketManager(): WebSocketManagerService {
  if (!_websocketManager) {
    _websocketManager = new WebSocketManagerService();
  }
  return _websocketManager;
}

// Export the singleton instance for direct use
export const websocketManager = getWebSocketManager();