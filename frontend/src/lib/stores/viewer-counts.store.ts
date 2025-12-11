/**
 * Viewer Counts Store
 * Manages real-time viewer count updates for channels
 * Requirements: 8.1, 8.2, 8.3
 */

import { writable } from 'svelte/store';
import type { ViewerCountEvent } from '$lib/types/websocket';
import { getWebSocketClient } from '$lib/services/websocket.service';

// Store for viewer counts - Map<channel, number>
export const viewerCounts = writable<Map<string, number>>(new Map());

// Store for viewer names - Map<channel, string[]>
export const viewerNames = writable<Map<string, string[]>>(new Map());

/**
 * Initialize viewer counts store with WebSocket event handling
 */
export function initializeViewerCountsStore() {
  const wsClient = getWebSocketClient();
  
  // Handle viewer count events
  wsClient.on('viewer_count', (event: ViewerCountEvent) => {
    const channel = event.channel;
    const count = event.data.count;
    const viewers = event.data.viewers;
    
    // Update viewer counts
    viewerCounts.update(counts => {
      const newCounts = new Map(counts);
      if (count > 0) {
        newCounts.set(channel, count);
      } else {
        newCounts.delete(channel);
      }
      return newCounts;
    });
    
    // Update viewer names
    viewerNames.update(names => {
      const newNames = new Map(names);
      if (viewers.length > 0) {
        newNames.set(channel, viewers);
      } else {
        newNames.delete(channel);
      }
      return newNames;
    });
  });
}

/**
 * Get viewer count for a specific channel
 */
export function getViewerCount(channel: string): number {
  let count = 0;
  viewerCounts.subscribe(counts => {
    count = counts.get(channel) || 0;
  })();
  return count;
}

/**
 * Get viewer names for a specific channel
 */
export function getViewerNames(channel: string): string[] {
  let names: string[] = [];
  viewerNames.subscribe(viewerNamesMap => {
    names = viewerNamesMap.get(channel) || [];
  })();
  return names;
}

/**
 * Check if a channel has multiple viewers
 */
export function hasMultipleViewers(channel: string): boolean {
  return getViewerCount(channel) > 1;
}

/**
 * Update viewer count manually (for testing or initial data)
 */
export function updateViewerCount(channel: string, count: number, viewers: string[] = []) {
  viewerCounts.update(counts => {
    const newCounts = new Map(counts);
    if (count > 0) {
      newCounts.set(channel, count);
    } else {
      newCounts.delete(channel);
    }
    return newCounts;
  });
  
  viewerNames.update(names => {
    const newNames = new Map(names);
    if (viewers.length > 0) {
      newNames.set(channel, viewers);
    } else {
      newNames.delete(channel);
    }
    return newNames;
  });
}

/**
 * Clear viewer count for a specific channel
 */
export function clearViewerCount(channel: string) {
  viewerCounts.update(counts => {
    const newCounts = new Map(counts);
    newCounts.delete(channel);
    return newCounts;
  });
  
  viewerNames.update(names => {
    const newNames = new Map(names);
    newNames.delete(channel);
    return newNames;
  });
}

/**
 * Clear all viewer counts
 */
export function clearAllViewerCounts() {
  viewerCounts.set(new Map());
  viewerNames.set(new Map());
}

/**
 * Get all channels with viewers
 */
export function getChannelsWithViewers(): string[] {
  let channels: string[] = [];
  viewerCounts.subscribe(counts => {
    channels = Array.from(counts.keys());
  })();
  return channels;
}

/**
 * Get total viewer count across all channels
 */
export function getTotalViewerCount(): number {
  let total = 0;
  viewerCounts.subscribe(counts => {
    total = Array.from(counts.values()).reduce((sum, count) => sum + count, 0);
  })();
  return total;
}