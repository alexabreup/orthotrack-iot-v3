/**
 * Audio Notification Service
 * Handles playing notification sounds for toast alerts
 * Requirements: 2.4
 */

import { toastSettings } from '$lib/stores/toast.store';
import { get } from 'svelte/store';

export class AudioService {
  private audioContext: AudioContext | null = null;
  private notificationSound: AudioBuffer | null = null;
  
  constructor() {
    this.initializeAudioContext();
  }
  
  /**
   * Initialize Web Audio API context
   */
  private async initializeAudioContext(): Promise<void> {
    try {
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      await this.loadNotificationSound();
    } catch (error) {
      console.warn('Audio context initialization failed:', error);
    }
  }
  
  /**
   * Load notification sound (using a simple beep tone)
   */
  private async loadNotificationSound(): Promise<void> {
    if (!this.audioContext) return;
    
    try {
      // Create a simple notification beep sound
      const sampleRate = this.audioContext.sampleRate;
      const duration = 0.3; // 300ms
      const frequency = 800; // 800Hz tone
      
      const buffer = this.audioContext.createBuffer(1, sampleRate * duration, sampleRate);
      const channelData = buffer.getChannelData(0);
      
      for (let i = 0; i < channelData.length; i++) {
        const t = i / sampleRate;
        // Create a beep with fade in/out to avoid clicks
        const envelope = Math.sin(Math.PI * t / duration);
        channelData[i] = Math.sin(2 * Math.PI * frequency * t) * envelope * 0.1;
      }
      
      this.notificationSound = buffer;
    } catch (error) {
      console.warn('Failed to create notification sound:', error);
    }
  }
  
  /**
   * Play notification sound if audio is enabled
   * Requirements: 2.4
   */
  async playNotification(): Promise<void> {
    const settings = get(toastSettings);
    
    // Check if audio is enabled in user settings
    if (!settings.audioEnabled) {
      return;
    }
    
    if (!this.audioContext || !this.notificationSound) {
      console.warn('Audio context or notification sound not available');
      return;
    }
    
    try {
      // Resume audio context if suspended (required by browser policies)
      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume();
      }
      
      // Create and play the sound
      const source = this.audioContext.createBufferSource();
      const gainNode = this.audioContext.createGain();
      
      source.buffer = this.notificationSound;
      source.connect(gainNode);
      gainNode.connect(this.audioContext.destination);
      
      // Set volume
      gainNode.gain.value = 0.3;
      
      source.start();
    } catch (error) {
      console.warn('Failed to play notification sound:', error);
    }
  }
  
  /**
   * Enable audio notifications
   */
  enableAudio(): void {
    toastSettings.update(settings => ({
      ...settings,
      audioEnabled: true
    }));
  }
  
  /**
   * Disable audio notifications
   */
  disableAudio(): void {
    toastSettings.update(settings => ({
      ...settings,
      audioEnabled: false
    }));
  }
  
  /**
   * Toggle audio notifications
   */
  toggleAudio(): void {
    const settings = get(toastSettings);
    toastSettings.update(current => ({
      ...current,
      audioEnabled: !settings.audioEnabled
    }));
  }
}

// Export singleton instance
export const audioService = new AudioService();