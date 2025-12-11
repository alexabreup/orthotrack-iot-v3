/**
 * Toast Notification Store
 * Manages toast notifications for alert events
 * Requirements: 2.2, 2.6
 */

import { writable } from 'svelte/store';
import { goto } from '$app/navigation';
import type { ToastNotification, ToastSettings } from '$lib/types/toast';
import type { AlertEvent } from '$lib/types/websocket';
import { audioService } from '$lib/services/audio.service';

// Store for active toast notifications
export const toasts = writable<ToastNotification[]>([]);

// Store for toast settings
export const toastSettings = writable<ToastSettings>({
  audioEnabled: true
});

// Toast manager class
class ToastManager {
  private toastList: ToastNotification[] = [];
  private timeouts: Map<string, NodeJS.Timeout> = new Map();
  
  constructor() {
    // Subscribe to store to keep internal state in sync
    toasts.subscribe(value => {
      this.toastList = value;
    });
  }
  
  /**
   * Add a new toast notification from alert event
   * Requirements: 2.2
   */
  addToastFromAlert(alertEvent: AlertEvent): void {
    const toast: ToastNotification = {
      id: `toast-${alertEvent.data.alert_id}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      severity: alertEvent.data.severity,
      message: alertEvent.data.message,
      patientName: alertEvent.data.patient_name,
      patientId: alertEvent.data.patient_id,
      timestamp: alertEvent.data.timestamp,
      autoRemoveDelay: 10000 // 10 seconds as per requirement 2.6
    };
    
    this.addToast(toast);
  }

  /**
   * Add a general error toast notification
   */
  addErrorToast(message: string, autoRemoveDelay: number = 5000): void {
    const toast: ToastNotification = {
      id: `error-toast-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      severity: 'critical',
      message: message,
      patientName: 'System',
      patientId: '',
      timestamp: Date.now(),
      autoRemoveDelay: autoRemoveDelay
    };
    
    this.addToast(toast);
  }

  /**
   * Add a general info toast notification
   */
  addInfoToast(message: string, autoRemoveDelay: number = 3000): void {
    const toast: ToastNotification = {
      id: `info-toast-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      severity: 'info',
      message: message,
      patientName: 'System',
      patientId: '',
      timestamp: Date.now(),
      autoRemoveDelay: autoRemoveDelay
    };
    
    this.addToast(toast);
  }
  
  /**
   * Add a toast notification
   */
  addToast(toast: ToastNotification): void {
    this.toastList = [...this.toastList, toast];
    toasts.set(this.toastList);
    
    // Set up auto-removal timeout (Requirement 2.6)
    const timeoutId = setTimeout(() => {
      this.removeToast(toast.id);
    }, toast.autoRemoveDelay);
    
    this.timeouts.set(toast.id, timeoutId);
    
    // Play audio notification if enabled (Requirement 2.4)
    audioService.playNotification();
  }
  
  /**
   * Remove a toast notification by ID
   * Requirements: 2.6
   */
  removeToast(id: string): void {
    // Clear the timeout if it exists
    const timeoutId = this.timeouts.get(id);
    if (timeoutId) {
      clearTimeout(timeoutId);
      this.timeouts.delete(id);
    }
    
    this.toastList = this.toastList.filter(toast => toast.id !== id);
    toasts.set(this.toastList);
  }
  
  /**
   * Handle toast click navigation
   * Requirements: 2.5
   */
  handleToastClick(patientId: string): void {
    goto(`/patients/${patientId}`);
  }
  
  /**
   * Clear all toasts
   */
  clearAll(): void {
    // Clear all timeouts
    this.timeouts.forEach(timeoutId => clearTimeout(timeoutId));
    this.timeouts.clear();
    
    this.toastList = [];
    toasts.set(this.toastList);
  }
  
  /**
   * Get current toast count
   */
  getCount(): number {
    return this.toastList.length;
  }
}

// Export singleton instance
export const toastManager = new ToastManager();

// Helper functions for external use
export function addToastFromAlert(alertEvent: AlertEvent): void {
  toastManager.addToastFromAlert(alertEvent);
}

export function addErrorToast(message: string, autoRemoveDelay?: number): void {
  toastManager.addErrorToast(message, autoRemoveDelay);
}

export function addInfoToast(message: string, autoRemoveDelay?: number): void {
  toastManager.addInfoToast(message, autoRemoveDelay);
}

export function removeToast(id: string): void {
  toastManager.removeToast(id);
}

export function handleToastClick(patientId: string): void {
  toastManager.handleToastClick(patientId);
}

export function clearAllToasts(): void {
  toastManager.clearAll();
}

// Export audio service for external use
export { audioService } from '$lib/services/audio.service';