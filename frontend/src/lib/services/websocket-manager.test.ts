/**
 * WebSocket Manager Service Tests
 * Basic functionality tests for the WebSocket manager integration
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { get } from 'svelte/store';
import { websocketManager } from './websocket-manager.service';

// Mock the auth service
vi.mock('./auth.service', () => ({
  authService: {
    getToken: vi.fn(() => 'mock-jwt-token'),
    logout: vi.fn()
  }
}));

// Mock the toast store
vi.mock('$lib/stores/toast.store', () => ({
  addErrorToast: vi.fn(),
  addInfoToast: vi.fn()
}));

// Mock navigation
vi.mock('$app/navigation', () => ({
  goto: vi.fn()
}));

describe('WebSocket Manager Service', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should initialize with disconnected state', () => {
    const state = get(websocketManager.state);
    expect(state.status).toBe('disconnected');
  });

  it('should provide access to WebSocket client methods', () => {
    expect(typeof websocketManager.subscribe).toBe('function');
    expect(typeof websocketManager.unsubscribe).toBe('function');
    expect(typeof websocketManager.on).toBe('function');
    expect(typeof websocketManager.off).toBe('function');
    expect(typeof websocketManager.getConnectionStatus).toBe('function');
    expect(typeof websocketManager.getSubscriptions).toBe('function');
  });

  it('should handle initialization with token', async () => {
    // This test verifies the manager can be initialized
    // The actual WebSocket connection will be mocked in the underlying service
    await expect(websocketManager.initialize()).resolves.not.toThrow();
  });

  it('should handle disconnection', () => {
    websocketManager.disconnect();
    const state = get(websocketManager.state);
    expect(state.status).toBe('disconnected');
  });
});