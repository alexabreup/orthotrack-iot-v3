/**
 * Toast Notification Types
 * Based on requirements 2.2, 2.3, 2.5
 */

export interface ToastNotification {
  id: string;
  severity: 'info' | 'warning' | 'critical';
  message: string;
  patientName: string;
  patientId: string;
  timestamp: number;
  autoRemoveDelay: number; // 10000ms
}

export interface ToastSettings {
  audioEnabled: boolean;
}