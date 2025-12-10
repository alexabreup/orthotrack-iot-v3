/**
 * Property-based tests for WebSocket service
 * Feature: realtime-monitoring
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import fc from 'fast-check';
import { WebSocketClient } from './websocket.service';

// Mock Event classes for Node environment
class MockEvent {
  type: string;
  constructor(type: string) {
    this.type = type;
  }
}

class MockCloseEvent extends MockEvent {
  code: number;
  reason: string;
  constructor(type: string, options: { code?: number; reason?: string } = {}) {
    super(type);
    this.code = options.code || 1000;
    this.reason = options.reason || '';
  }
}

class MockMessageEvent extends MockEvent {
  data: any;
  constructor(type: string, options: { data?: any } = {}) {
    super(type);
    this.data = options.data;
  }
}

// Mock WebSocket
class MockWebSocket {
  static CONNECTING = 0;
  static OPEN = 1;
  static CLOSING = 2;
  static CLOSED = 3;

  readyState = MockWebSocket.CONNECTING;
  url: string;
  onopen: ((event: MockEvent) => void) | null = null;
  onmessage: ((event: MockMessageEvent) => void) | null = null;
  onclose: ((event: MockCloseEvent) => void) | null = null;
  onerror: ((event: MockEvent) => void) | null = null;

  private listeners: Map<string, ((event: any) => void)[]> = new Map();

  constructor(url: string) {
    this.url = url;
    // Simulate async connection
    setTimeout(() => {
      this.readyState = MockWebSocket.OPEN;
      this.dispatchEvent('open', new MockEvent('open'));
    }, 10);
  }

  addEventListener(type: string, listener: (event: any) => void) {
    if (!this.listeners.has(type)) {
      this.listeners.set(type, []);
    }
    this.listeners.get(type)!.push(listener);
  }

  removeEventListener(type: string, listener: (event: any) => void) {
    const listeners = this.listeners.get(type);
    if (listeners) {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  dispatchEvent(type: string, event: any) {
    const listeners = this.listeners.get(type) || [];
    listeners.forEach(listener => listener(event));
  }

  send(data: string) {
    if (this.readyState !== MockWebSocket.OPEN) {
      throw new Error('WebSocket is not open');
    }
  }

  close(code?: number, reason?: string) {
    this.readyState = MockWebSocket.CLOSED;
    const closeEvent = new MockCloseEvent('close', { code: code || 1000, reason: reason || '' });
    this.dispatchEvent('close', closeEvent);
  }

  // Helper method to simulate connection failure
  simulateError() {
    this.readyState = MockWebSocket.CLOSED;
    this.dispatchEvent('error', new MockEvent('error'));
    this.dispatchEvent('close', new MockCloseEvent('close', { code: 1006, reason: 'Connection failed' }));
  }
}

// Mock global WebSocket and window
global.WebSocket = MockWebSocket as any;
global.window = {
  setTimeout: global.setTimeout,
  clearTimeout: global.clearTimeout,
  setInterval: global.setInterval,
  clearInterval: global.clearInterval,
  location: {
    protocol: 'http:',
    hostname: 'localhost'
  }
} as any;

describe('WebSocket Service Property Tests', () => {
  let client: WebSocketClient;
  let originalSetTimeout: typeof setTimeout;
  let originalClearTimeout: typeof clearTimeout;
  let timeouts: Map<number, { callback: () => void; delay: number }>;
  let timeoutId = 0;

  beforeEach(() => {
    client = new WebSocketClient();
    timeouts = new Map();
    timeoutId = 0;

    // Mock setTimeout and clearTimeout to control timing
    originalSetTimeout = global.setTimeout;
    originalClearTimeout = global.clearTimeout;

    global.setTimeout = vi.fn((callback: () => void, delay: number) => {
      const id = ++timeoutId;
      timeouts.set(id, { callback, delay });
      return id as any;
    });

    global.clearTimeout = vi.fn((id: number) => {
      timeouts.delete(id);
    });
  });

  afterEach(() => {
    client.disconnect();
    global.setTimeout = originalSetTimeout;
    global.clearTimeout = originalClearTimeout;
    vi.clearAllMocks();
  });

  /**
   * Feature: realtime-monitoring, Property 14: Exponential backoff
   * Validates: Requirements 4.2, 4.3
   */
  it('should implement exponential backoff for reconnection attempts', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 1, max: 5 }), // number of failures
        async (numFailures) => {
          const delays: number[] = [];

          // Track reconnection events
          client.on('reconnecting', (data) => {
            delays.push(data.delay);
          });

          // Start connection
          client.connect({ token: 'test-token' });

          // Simulate connection failures
          for (let i = 0; i < numFailures; i++) {
            // Wait for connection attempt
            await new Promise(resolve => setTimeout(resolve, 10));
            
            // Simulate connection failure
            const mockWs = (client as any).ws as MockWebSocket;
            if (mockWs) {
              mockWs.simulateError();
            }

            // Trigger the reconnection timeout
            const timeoutEntries = Array.from(timeouts.entries());
            if (timeoutEntries.length > 0) {
              const [id, { callback }] = timeoutEntries[0];
              timeouts.delete(id);
              callback();
            }
          }

          // Verify exponential backoff pattern
          if (delays.length > 0) {
            // First delay should be 1000ms (1 second)
            expect(delays[0]).toBe(1000);

            // Each subsequent delay should double, up to 30 seconds max
            for (let i = 1; i < delays.length; i++) {
              const expectedDelay = Math.min(delays[i - 1] * 2, 30000);
              expect(delays[i]).toBe(expectedDelay);
            }

            // No delay should exceed 30 seconds
            delays.forEach(delay => {
              expect(delay).toBeLessThanOrEqual(30000);
            });
          }
        }
      ),
      { numRuns: 20, timeout: 10000 }
    );
  }, 15000);

  it('should reset reconnection delay on successful connection', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 2, max: 3 }), // number of failures before success
        async (numFailures) => {
          const delays: number[] = [];

          client.on('reconnecting', (data) => {
            delays.push(data.delay);
          });

          // Start connection
          client.connect({ token: 'test-token' });

          // Simulate failures
          for (let i = 0; i < numFailures; i++) {
            await new Promise(resolve => setTimeout(resolve, 10));
            
            const mockWs = (client as any).ws as MockWebSocket;
            if (mockWs) {
              mockWs.simulateError();
            }

            // Trigger reconnection
            const timeoutEntries = Array.from(timeouts.entries());
            if (timeoutEntries.length > 0) {
              const [id, { callback }] = timeoutEntries[0];
              timeouts.delete(id);
              callback();
            }
          }

          // Allow successful connection
          await new Promise(resolve => setTimeout(resolve, 20));

          // Disconnect and reconnect to test delay reset
          client.disconnect();
          delays.length = 0; // Clear previous delays
          
          client.connect({ token: 'test-token' });
          await new Promise(resolve => setTimeout(resolve, 10));
          
          const mockWs = (client as any).ws as MockWebSocket;
          if (mockWs) {
            mockWs.simulateError();
          }

          // Trigger reconnection
          const timeoutEntries = Array.from(timeouts.entries());
          if (timeoutEntries.length > 0) {
            const [id, { callback }] = timeoutEntries[0];
            timeouts.delete(id);
            callback();
          }

          // First delay after successful connection should be back to 1000ms
          if (delays.length > 0) {
            expect(delays[0]).toBe(1000);
          }
        }
      ),
      { numRuns: 10, timeout: 5000 }
    );
  }, 10000);

  /**
   * Feature: realtime-monitoring, Property 15: Subscription restoration
   * Validates: Requirements 4.4
   */
  it('should restore all subscriptions after reconnection', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.array(fc.string({ minLength: 1, maxLength: 10 }), { minLength: 1, maxLength: 5 }), // subscription channels
        async (channels) => {
          const sentMessages: any[] = [];
          let isConnected = false;

          // Mock WebSocket send to capture messages
          const originalSend = MockWebSocket.prototype.send;
          MockWebSocket.prototype.send = function(data: string) {
            if (isConnected) {
              sentMessages.push(JSON.parse(data));
            }
          };

          try {
            // Connect and wait for connection
            client.connect({ token: 'test-token' });
            await new Promise(resolve => setTimeout(resolve, 15));
            isConnected = true;

            // Subscribe to channels
            const uniqueChannels = [...new Set(channels)]; // Remove duplicates
            uniqueChannels.forEach(channel => {
              client.subscribe(channel);
            });

            // Clear sent messages to focus on restoration
            sentMessages.length = 0;

            // Simulate disconnection
            const mockWs = (client as any).ws as MockWebSocket;
            if (mockWs) {
              isConnected = false;
              mockWs.simulateError();
            }

            // Wait for reconnection attempt
            await new Promise(resolve => setTimeout(resolve, 10));

            // Trigger reconnection
            const timeoutEntries = Array.from(timeouts.entries());
            if (timeoutEntries.length > 0) {
              const [id, { callback }] = timeoutEntries[0];
              timeouts.delete(id);
              callback();
            }

            // Wait for new connection
            await new Promise(resolve => setTimeout(resolve, 15));
            isConnected = true;

            // Verify that all subscriptions were restored
            const subscribeMessages = sentMessages.filter(msg => msg.type === 'subscribe');
            const restoredChannels = subscribeMessages.map(msg => msg.channel);

            // All original channels should be restored
            uniqueChannels.forEach(channel => {
              expect(restoredChannels).toContain(channel);
            });

            // Should have exactly the same number of subscriptions
            expect(restoredChannels.length).toBe(uniqueChannels.length);

            // Verify client still has the subscriptions
            const clientSubscriptions = client.getSubscriptions();
            uniqueChannels.forEach(channel => {
              expect(clientSubscriptions).toContain(channel);
            });

          } finally {
            // Restore original send method
            MockWebSocket.prototype.send = originalSend;
          }
        }
      ),
      { numRuns: 20, timeout: 3000 }
    );
  }, 8000);

  it('should maintain subscription state across multiple reconnections', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.array(fc.string({ minLength: 1, maxLength: 15 }), { minLength: 1, maxLength: 5 }),
        fc.integer({ min: 2, max: 4 }), // number of reconnections
        async (channels, numReconnections) => {
          const sentMessages: any[] = [];
          let isConnected = false;

          // Mock WebSocket send
          const originalSend = MockWebSocket.prototype.send;
          MockWebSocket.prototype.send = function(data: string) {
            if (isConnected) {
              sentMessages.push(JSON.parse(data));
            }
          };

          try {
            // Initial connection
            client.connect({ token: 'test-token' });
            await new Promise(resolve => setTimeout(resolve, 20));
            isConnected = true;

            // Subscribe to channels
            const uniqueChannels = [...new Set(channels)];
            uniqueChannels.forEach(channel => {
              client.subscribe(channel);
            });

            // Perform multiple reconnections
            for (let i = 0; i < numReconnections; i++) {
              sentMessages.length = 0; // Clear messages

              // Disconnect
              const mockWs = (client as any).ws as MockWebSocket;
              if (mockWs) {
                isConnected = false;
                mockWs.simulateError();
              }

              await new Promise(resolve => setTimeout(resolve, 20));

              // Reconnect
              const timeoutEntries = Array.from(timeouts.entries());
              if (timeoutEntries.length > 0) {
                const [id, { callback }] = timeoutEntries[0];
                timeouts.delete(id);
                callback();
              }

              await new Promise(resolve => setTimeout(resolve, 20));
              isConnected = true;

              // Verify subscriptions were restored
              const subscribeMessages = sentMessages.filter(msg => msg.type === 'subscribe');
              const restoredChannels = subscribeMessages.map(msg => msg.channel);

              uniqueChannels.forEach(channel => {
                expect(restoredChannels).toContain(channel);
              });
            }

            // Final verification - client should still have all subscriptions
            const finalSubscriptions = client.getSubscriptions();
            expect(finalSubscriptions.length).toBe(uniqueChannels.length);
            uniqueChannels.forEach(channel => {
              expect(finalSubscriptions).toContain(channel);
            });

          } finally {
            MockWebSocket.prototype.send = originalSend;
          }
        }
      ),
      { numRuns: 50 }
    );
  });
});