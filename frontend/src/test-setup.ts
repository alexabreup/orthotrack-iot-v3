/**
 * Test setup file for mocking browser APIs in Node.js environment
 */

import { vi } from 'vitest';

// Mock WebSocket with proper event simulation
class MockWebSocket {
  static CONNECTING = 0;
  static OPEN = 1;
  static CLOSING = 2;
  static CLOSED = 3;

  url: string;
  readyState: number = MockWebSocket.CONNECTING;
  onopen: ((event: Event) => void) | null = null;
  onclose: ((event: CloseEvent) => void) | null = null;
  onmessage: ((event: MessageEvent) => void) | null = null;
  onerror: ((event: Event) => void) | null = null;

  private eventListeners: Map<string, Function[]> = new Map();
  private shouldFailConnection = false;
  private connectionDelay = 10;

  constructor(url: string) {
    this.url = url;
    
    // Simulate async connection
    setTimeout(() => {
      if (this.shouldFailConnection) {
        this.readyState = MockWebSocket.CLOSED;
        this.triggerError();
      } else {
        this.readyState = MockWebSocket.OPEN;
        this.triggerOpen();
      }
    }, this.connectionDelay);
  }

  addEventListener(type: string, listener: Function) {
    if (!this.eventListeners.has(type)) {
      this.eventListeners.set(type, []);
    }
    this.eventListeners.get(type)!.push(listener);
  }

  removeEventListener(type: string, listener: Function) {
    const listeners = this.eventListeners.get(type);
    if (listeners) {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  send = vi.fn();

  close() {
    this.readyState = MockWebSocket.CLOSED;
    this.triggerClose();
  }

  // Test helper methods
  simulateError() {
    this.shouldFailConnection = true;
    if (this.readyState === MockWebSocket.CONNECTING) {
      setTimeout(() => {
        this.readyState = MockWebSocket.CLOSED;
        this.triggerError();
      }, this.connectionDelay);
    } else {
      this.readyState = MockWebSocket.CLOSED;
      this.triggerError();
    }
  }

  simulateSuccess() {
    this.shouldFailConnection = false;
    if (this.readyState === MockWebSocket.CONNECTING) {
      setTimeout(() => {
        this.readyState = MockWebSocket.OPEN;
        this.triggerOpen();
      }, this.connectionDelay);
    }
  }

  private triggerOpen() {
    const event = new Event('open');
    this.onopen?.(event);
    this.eventListeners.get('open')?.forEach(listener => listener(event));
  }

  private triggerClose() {
    const event = new CloseEvent('close', { code: 1000, reason: 'Normal closure' });
    this.onclose?.(event);
    this.eventListeners.get('close')?.forEach(listener => listener(event));
  }

  private triggerError() {
    const event = new Event('error');
    this.onerror?.(event);
    this.eventListeners.get('error')?.forEach(listener => listener(event));
    // Also trigger close after error with non-normal code
    setTimeout(() => {
      this.readyState = MockWebSocket.CLOSED;
      const closeEvent = new CloseEvent('close', { code: 1006, reason: 'Connection failed' });
      this.onclose?.(closeEvent);
      this.eventListeners.get('close')?.forEach(listener => listener(closeEvent));
    }, 5);
  }

  private triggerMessage(data: any) {
    const event = new MessageEvent('message', { data: JSON.stringify(data) });
    this.onmessage?.(event);
    this.eventListeners.get('message')?.forEach(listener => listener(event));
  }
}

global.WebSocket = MockWebSocket as any;

// Mock Event constructors
global.Event = class MockEvent {
  type: string;
  constructor(type: string) {
    this.type = type;
  }
} as any;

global.CloseEvent = class MockCloseEvent extends Event {
  code: number;
  reason: string;
  constructor(type: string, options: { code: number; reason: string }) {
    super(type);
    this.code = options.code;
    this.reason = options.reason;
  }
} as any;

global.MessageEvent = class MockMessageEvent extends Event {
  data: any;
  constructor(type: string, options: { data: any }) {
    super(type);
    this.data = options.data;
  }
} as any;

// Mock window object
Object.defineProperty(global, 'window', {
  value: {
    setTimeout: global.setTimeout,
    clearTimeout: global.clearTimeout,
    setInterval: global.setInterval,
    clearInterval: global.clearInterval,
    location: {
      protocol: 'http:',
      host: 'localhost:3000'
    }
  },
  writable: true
});

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
  length: 0,
  key: vi.fn()
};

Object.defineProperty(global, 'localStorage', {
  value: localStorageMock,
  writable: true
});

// Mock Audio API
global.Audio = vi.fn().mockImplementation(() => ({
  play: vi.fn().mockResolvedValue(undefined),
  pause: vi.fn(),
  load: vi.fn(),
  addEventListener: vi.fn(),
  removeEventListener: vi.fn(),
  volume: 1,
  muted: false,
  paused: true,
  ended: false,
  currentTime: 0,
  duration: 0
}));