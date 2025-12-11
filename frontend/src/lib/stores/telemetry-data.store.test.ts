/**
 * Property-Based Tests for Telemetry Data Store
 * Feature: realtime-monitoring, Property 11: Chart buffer limit
 * Validates: Requirements 3.3
 */

import { describe, it, expect, beforeEach } from 'vitest';
import * as fc from 'fast-check';
import { get } from 'svelte/store';
import { 
  telemetryData, 
  addTelemetryPoint, 
  clearAllTelemetryData,
  getTelemetryDataCount 
} from './telemetry-data.store';
import type { TelemetryPoint } from '$lib/types/websocket';

describe('Telemetry Data Store - Property Tests', () => {
  beforeEach(() => {
    clearAllTelemetryData();
  });

  /**
   * Feature: realtime-monitoring, Property 11: Chart buffer limit
   * For any chart with 100 data points, adding a new point should remove the oldest point first
   * Validates: Requirements 3.3
   */
  it('should enforce 100-point buffer limit by removing oldest points', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 20 }), // device_id
        fc.array(
          fc.record({
            timestamp: fc.integer({ min: 1000000000000, max: 9999999999999 }),
            sensors: fc.record({
              temperature: fc.option(fc.float({ min: -50, max: 100 })),
              battery_level: fc.option(fc.float({ min: 0, max: 100 })),
              accelerometer: fc.option(fc.record({
                x: fc.float({ min: -10, max: 10 }),
                y: fc.float({ min: -10, max: 10 }),
                z: fc.float({ min: -10, max: 10 })
              }))
            })
          }),
          { minLength: 101, maxLength: 200 } // Generate more than 100 points
        ),
        (deviceId: string, points: TelemetryPoint[]) => {
          // Add all points to the store
          points.forEach(point => {
            addTelemetryPoint(deviceId, point);
          });

          // Get the current data from the store
          const currentData = get(telemetryData);
          const deviceData = currentData.get(deviceId) || [];

          // Assert that the buffer limit is enforced
          expect(deviceData.length).toBeLessThanOrEqual(100);
          
          // If we added more than 100 points, verify we have exactly 100
          if (points.length > 100) {
            expect(deviceData.length).toBe(100);
            
            // Verify that the stored points are the last 100 points we added
            const expectedPoints = points.slice(-100);
            expect(deviceData).toEqual(expectedPoints);
            
            // Verify that the oldest points were removed
            const firstStoredPoint = deviceData[0];
            const firstExpectedPoint = expectedPoints[0];
            expect(firstStoredPoint).toEqual(firstExpectedPoint);
            
            // Verify that the newest points are preserved
            const lastStoredPoint = deviceData[deviceData.length - 1];
            const lastExpectedPoint = expectedPoints[expectedPoints.length - 1];
            expect(lastStoredPoint).toEqual(lastExpectedPoint);
          } else {
            // If we added 100 or fewer points, all should be preserved
            expect(deviceData.length).toBe(points.length);
            expect(deviceData).toEqual(points);
          }
        }
      ),
      { numRuns: 100 } // Run 100 iterations as specified in design document
    );
  });

  it('should maintain buffer limit when adding points one by one', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 20 }), // device_id
        fc.array(
          fc.record({
            timestamp: fc.integer({ min: 1000000000000, max: 9999999999999 }),
            sensors: fc.record({
              temperature: fc.option(fc.float({ min: -50, max: 100 })),
              battery_level: fc.option(fc.float({ min: 0, max: 100 })),
              accelerometer: fc.option(fc.record({
                x: fc.float({ min: -10, max: 10 }),
                y: fc.float({ min: -10, max: 10 }),
                z: fc.float({ min: -10, max: 10 })
              }))
            })
          }),
          { minLength: 150, maxLength: 300 } // Generate many points
        ),
        (deviceId: string, points: TelemetryPoint[]) => {
          // Clear all data before this test run
          clearAllTelemetryData();
          
          // Add points one by one and verify buffer limit after each addition
          points.forEach((point, index) => {
            addTelemetryPoint(deviceId, point);
            
            const currentCount = getTelemetryDataCount(deviceId);
            const expectedCount = Math.min(index + 1, 100);
            
            expect(currentCount).toBe(expectedCount);
            expect(currentCount).toBeLessThanOrEqual(100);
          });
        }
      ),
      { numRuns: 100 }
    );
  });

  it('should handle multiple devices independently', () => {
    fc.assert(
      fc.property(
        fc.array(
          fc.record({
            deviceId: fc.string({ minLength: 1, maxLength: 20 }),
            points: fc.array(
              fc.record({
                timestamp: fc.integer({ min: 1000000000000, max: 9999999999999 }),
                sensors: fc.record({
                  temperature: fc.option(fc.float({ min: -50, max: 100 }))
                })
              }),
              { minLength: 50, maxLength: 150 }
            )
          }),
          { minLength: 2, maxLength: 5 }
        ),
        (deviceDataArray) => {
          // Clear all data before this test run
          clearAllTelemetryData();
          
          // Add points for each device
          deviceDataArray.forEach(({ deviceId, points }) => {
            points.forEach(point => {
              addTelemetryPoint(deviceId, point);
            });
          });

          // Verify each device maintains its own buffer limit
          deviceDataArray.forEach(({ deviceId, points }) => {
            const deviceCount = getTelemetryDataCount(deviceId);
            const expectedCount = Math.min(points.length, 100);
            
            expect(deviceCount).toBe(expectedCount);
            expect(deviceCount).toBeLessThanOrEqual(100);
          });
        }
      ),
      { numRuns: 100 }
    );
  });
});