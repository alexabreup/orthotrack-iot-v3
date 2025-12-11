/**
 * Subscription Manager Service
 * Automatically manages WebSocket subscriptions based on current route
 */

import { websocketManager } from './websocket-manager.service';
import { authService } from './auth.service';

export interface RouteSubscription {
  pattern: RegExp;
  getChannels: (params: Record<string, string>) => string[];
}

class SubscriptionManagerService {
  private currentSubscriptions: Set<string> = new Set();
  private routeSubscriptions: RouteSubscription[] = [];

  constructor() {
    this.setupRouteSubscriptions();
  }

  /**
   * Setup route-based subscription patterns
   */
  private setupRouteSubscriptions(): void {
    this.routeSubscriptions = [
      // Dashboard page - subscribe to global dashboard stats
      {
        pattern: /^\/$/,
        getChannels: () => ['dashboard', 'alerts:global']
      },
      
      // Devices list page - subscribe to device status updates
      {
        pattern: /^\/devices\/?$/,
        getChannels: () => ['alerts:global']
      },
      
      // Device details page - subscribe to specific device
      {
        pattern: /^\/devices\/([^\/]+)\/?$/,
        getChannels: (params) => [
          `device:${params.deviceId}`,
          'alerts:global'
        ]
      },
      
      // Patients list page - subscribe to global alerts
      {
        pattern: /^\/patients\/?$/,
        getChannels: () => ['alerts:global']
      },
      
      // Patient details page - subscribe to specific patient
      {
        pattern: /^\/patients\/([^\/]+)\/?$/,
        getChannels: (params) => [
          `patient:${params.patientId}`,
          'alerts:global'
        ]
      },
      
      // Reports page - subscribe to dashboard stats
      {
        pattern: /^\/reports\/?$/,
        getChannels: () => ['dashboard']
      },
      
      // Alerts page - subscribe to global alerts
      {
        pattern: /^\/alerts\/?$/,
        getChannels: () => ['alerts:global']
      }
    ];
  }

  /**
   * Handle route change and update subscriptions
   */
  handleRouteChange(pathname: string): void {
    // Skip subscription management for login page
    if (pathname === '/login' || !authService.isAuthenticated()) {
      this.unsubscribeAll();
      return;
    }

    const newChannels = this.getChannelsForRoute(pathname);
    this.updateSubscriptions(newChannels);
  }

  /**
   * Get channels that should be subscribed for a given route
   */
  private getChannelsForRoute(pathname: string): string[] {
    const allChannels: string[] = [];

    for (const routeSubscription of this.routeSubscriptions) {
      const match = pathname.match(routeSubscription.pattern);
      if (match) {
        // Extract parameters from the match
        const params: Record<string, string> = {};
        
        // For device details: /devices/123 -> params.deviceId = "123"
        if (routeSubscription.pattern.source.includes('devices') && match[1]) {
          params.deviceId = match[1];
        }
        
        // For patient details: /patients/456 -> params.patientId = "456"
        if (routeSubscription.pattern.source.includes('patients') && match[1]) {
          params.patientId = match[1];
        }

        const channels = routeSubscription.getChannels(params);
        allChannels.push(...channels);
      }
    }

    // Remove duplicates
    return [...new Set(allChannels)];
  }

  /**
   * Update subscriptions to match the new set of channels
   */
  private updateSubscriptions(newChannels: string[]): void {
    const newChannelsSet = new Set(newChannels);
    
    // Unsubscribe from channels that are no longer needed
    for (const channel of this.currentSubscriptions) {
      if (!newChannelsSet.has(channel)) {
        console.log(`Unsubscribing from channel: ${channel}`);
        websocketManager.unsubscribe(channel);
      }
    }
    
    // Subscribe to new channels
    for (const channel of newChannels) {
      if (!this.currentSubscriptions.has(channel)) {
        console.log(`Subscribing to channel: ${channel}`);
        websocketManager.subscribe(channel);
      }
    }
    
    // Update current subscriptions
    this.currentSubscriptions = newChannelsSet;
  }

  /**
   * Unsubscribe from all channels
   */
  unsubscribeAll(): void {
    for (const channel of this.currentSubscriptions) {
      console.log(`Unsubscribing from channel: ${channel}`);
      websocketManager.unsubscribe(channel);
    }
    this.currentSubscriptions.clear();
  }

  /**
   * Get current subscriptions
   */
  getCurrentSubscriptions(): string[] {
    return Array.from(this.currentSubscriptions);
  }

  /**
   * Manually subscribe to additional channels (for special cases)
   */
  subscribe(channel: string): void {
    if (!this.currentSubscriptions.has(channel)) {
      console.log(`Manually subscribing to channel: ${channel}`);
      websocketManager.subscribe(channel);
      this.currentSubscriptions.add(channel);
    }
  }

  /**
   * Manually unsubscribe from channels (for special cases)
   */
  unsubscribe(channel: string): void {
    if (this.currentSubscriptions.has(channel)) {
      console.log(`Manually unsubscribing from channel: ${channel}`);
      websocketManager.unsubscribe(channel);
      this.currentSubscriptions.delete(channel);
    }
  }
}

// Singleton instance
let subscriptionManagerInstance: SubscriptionManagerService | null = null;

export function getSubscriptionManager(): SubscriptionManagerService {
  if (!subscriptionManagerInstance) {
    subscriptionManagerInstance = new SubscriptionManagerService();
  }
  return subscriptionManagerInstance;
}

// Export the singleton instance for direct use
export const subscriptionManager = getSubscriptionManager();