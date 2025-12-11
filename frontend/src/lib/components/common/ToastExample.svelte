<!--
  Example usage of the Toast Notification System
  This component demonstrates how to integrate toasts with WebSocket events
-->
<script lang="ts">
  import { onMount } from 'svelte';
  import { toasts, addToastFromAlert, toastSettings, audioService } from '$lib/stores/toast.store';
  import ToastContainer from './ToastContainer.svelte';
  import type { AlertEvent } from '$lib/types/websocket';
  
  // Example function to simulate receiving an alert event
  function simulateAlert() {
    const alertEvent: AlertEvent = {
      type: 'alert_created',
      channel: 'patient:123',
      data: {
        alert_id: `alert-${Date.now()}`,
        patient_id: '123',
        patient_name: 'João Silva',
        severity: 'critical',
        message: 'Dispositivo desconectado há mais de 30 minutos',
        timestamp: Date.now()
      }
    };
    
    addToastFromAlert(alertEvent);
  }
  
  function toggleAudio() {
    audioService.toggleAudio();
  }
</script>

<div class="p-4 space-y-4">
  <h3 class="text-lg font-semibold">Toast Notification System</h3>
  
  <div class="space-x-2">
    <button 
      on:click={simulateAlert}
      class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
    >
      Simulate Critical Alert
    </button>
    
    <button 
      on:click={toggleAudio}
      class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
    >
      Toggle Audio: {$toastSettings.audioEnabled ? 'ON' : 'OFF'}
    </button>
  </div>
  
  <div class="text-sm text-gray-600">
    <p>Active toasts: {$toasts.length}</p>
    <p>Toasts auto-remove after 10 seconds</p>
    <p>Click on a toast to navigate to patient details</p>
  </div>
</div>

<!-- Toast Container - should be placed in the main layout -->
<ToastContainer />