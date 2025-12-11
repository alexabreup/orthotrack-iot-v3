/**
 * Property-Based Tests for Toast Store
 * Feature: realtime-monitoring, Property 8: Toast auto-removal
 * Validates: Requirements 2.6
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { get } from 'svelte/store';
import fc from 'fast-check';
import { toasts, toastManager, addToastFromAlert } from './toast.store';
import type { ToastNotification } from '$lib/types/toast';
import type { AlertEvent } from '$lib/types/websocket';

// Mock the audio service to avoid audio context issues in tests
vi.mock('$lib/services/audio.service', () => ({
  audioService: {
    playNotification: vi.fn()
  }
}));

// Mock navigation
vi.mock('$app/navigation', () => ({
  goto: vi.fn()
}));

describe('Toast Store Property Tests', () => {
  beforeEach(() => {
    // Clear all toasts before each test
    toastManager.clearAll();
    vi.clearAllTimers();
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  /**
   * Property 8: Toast auto-removal
   * For any toast notification, if not interacted with for 10 seconds, 
   * the system should automatically remove it
   * Validates: Requirements 2.6
   */
  it('Property 8: Toast auto-removal - any toast should be automatically removed after 10 seconds', () => {
    fc.assert(
      fc.property(
        // Generate arbitrary alert events
        fc.record({
          alert_id: fc.string({ minLength: 1, maxLength: 50 }),
          patient_id: fc.string({ minLength: 1, maxLength: 20 }),
          patient_name: fc.string({ minLength: 1, maxLength: 100 }),
          severity: fc.constantFrom('info', 'warning', 'critical'),
          message: fc.string({ minLength: 1, maxLength: 200 }),
          timestamp: fc.integer({ min: Date.now() - 86400000, max: Date.now() })
        }),
        (alertData) => {
          // Clear state for each property test iteration
          toastManager.clearAll();
          vi.clearAllTimers();
          
          // Create alert event
          const alertEvent: AlertEvent = {
            type: 'alert_created',
            channel: `patient:${alertData.patient_id}`,
            data: alertData
          };

          // Add toast from alert event
          addToastFromAlert(alertEvent);

          // Verify toast was added
          const initialToasts = get(toasts);
          expect(initialToasts).toHaveLength(1);
          
          const addedToast = initialToasts[0];
          expect(addedToast.severity).toBe(alertData.severity);
          expect(addedToast.message).toBe(alertData.message);
          expect(addedToast.patientName).toBe(alertData.patient_name);
          expect(addedToast.patientId).toBe(alertData.patient_id);
          expect(addedToast.autoRemoveDelay).toBe(10000); // 10 seconds

          // Fast-forward time by 9.9 seconds (just before auto-removal)
          vi.advanceTimersByTime(9900);
          
          // Toast should still be present
          const toastsBeforeRemoval = get(toasts);
          expect(toastsBeforeRemoval).toHaveLength(1);
          expect(toastsBeforeRemoval[0].id).toBe(addedToast.id);

          // Fast-forward time by another 200ms (total 10.1 seconds)
          vi.advanceTimersByTime(200);

          // Toast should now be automatically removed
          const toastsAfterRemoval = get(toasts);
          expect(toastsAfterRemoval).toHaveLength(0);
        }
      ),
      { numRuns: 100 } // Run 100 iterations as specified in design document
    );
  });

  it('Property 8 Extension: Multiple toasts should each auto-remove after their individual delays', () => {
    fc.assert(
      fc.property(
        // Generate 2-3 alert events (smaller range for simpler testing)
        fc.array(
          fc.record({
            alert_id: fc.string({ minLength: 1, maxLength: 50 }),
            patient_id: fc.string({ minLength: 1, maxLength: 20 }),
            patient_name: fc.string({ minLength: 1, maxLength: 100 }),
            severity: fc.constantFrom('info', 'warning', 'critical'),
            message: fc.string({ minLength: 1, maxLength: 200 }),
            timestamp: fc.integer({ min: Date.now() - 86400000, max: Date.now() })
          }),
          { minLength: 2, maxLength: 3 }
        ),
        (alertsData) => {
          // Clear state for each property test iteration
          toastManager.clearAll();
          vi.clearAllTimers();
          
          // Add all toasts simultaneously (no delays between them)
          alertsData.forEach((alertData) => {
            const alertEvent: AlertEvent = {
              type: 'alert_created',
              channel: `patient:${alertData.patient_id}`,
              data: alertData
            };
            addToastFromAlert(alertEvent);
          });

          // Verify all toasts were added
          const initialToasts = get(toasts);
          expect(initialToasts).toHaveLength(alertsData.length);

          // Fast-forward to just before auto-removal (9.9 seconds)
          vi.advanceTimersByTime(9900);
          
          // All toasts should still be present
          const toastsBeforeRemoval = get(toasts);
          expect(toastsBeforeRemoval).toHaveLength(alertsData.length);

          // Fast-forward past the auto-removal time (total 10.1 seconds)
          vi.advanceTimersByTime(200);

          // All toasts should now be removed
          const toastsAfterRemoval = get(toasts);
          expect(toastsAfterRemoval).toHaveLength(0);
        }
      ),
      { numRuns: 30 }
    );
  });

  it('Property 8 Edge Case: Manual removal should cancel auto-removal timer', () => {
    fc.assert(
      fc.property(
        fc.record({
          alert_id: fc.string({ minLength: 1, maxLength: 50 }),
          patient_id: fc.string({ minLength: 1, maxLength: 20 }),
          patient_name: fc.string({ minLength: 1, maxLength: 100 }),
          severity: fc.constantFrom('info', 'warning', 'critical'),
          message: fc.string({ minLength: 1, maxLength: 200 }),
          timestamp: fc.integer({ min: Date.now() - 86400000, max: Date.now() })
        }),
        (alertData) => {
          // Clear state for each property test iteration
          toastManager.clearAll();
          vi.clearAllTimers();
          
          const alertEvent: AlertEvent = {
            type: 'alert_created',
            channel: `patient:${alertData.patient_id}`,
            data: alertData
          };

          // Add toast
          addToastFromAlert(alertEvent);
          const initialToasts = get(toasts);
          expect(initialToasts).toHaveLength(1);
          
          const toastId = initialToasts[0].id;

          // Fast-forward partway through the auto-removal delay
          vi.advanceTimersByTime(5000); // 5 seconds

          // Manually remove the toast
          toastManager.removeToast(toastId);

          // Verify toast was removed immediately
          const toastsAfterManualRemoval = get(toasts);
          expect(toastsAfterManualRemoval).toHaveLength(0);

          // Fast-forward past the original auto-removal time
          vi.advanceTimersByTime(6000); // Total 11 seconds

          // Should still be empty (no phantom removal)
          const finalToasts = get(toasts);
          expect(finalToasts).toHaveLength(0);
        }
      ),
      { numRuns: 50 }
    );
  });
});