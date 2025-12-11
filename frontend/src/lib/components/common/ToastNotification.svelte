<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import type { ToastNotification } from '$lib/types/toast';
  
  export let toast: ToastNotification;
  
  const dispatch = createEventDispatcher<{
    click: { patientId: string };
    remove: { id: string };
  }>();
  
  // Auto-removal is now handled by the toast store
  
  function handleClick() {
    dispatch('click', { patientId: toast.patientId });
  }
  
  function handleClose() {
    clearTimeout(timeoutId);
    dispatch('remove', { id: toast.id });
  }
  
  // Get severity styling
  $: severityClasses = {
    info: 'bg-blue-50 border-blue-200 text-blue-800',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-800',
    critical: 'bg-red-50 border-red-200 text-red-800'
  }[toast.severity];
  
  $: severityIcon = {
    info: '🔵',
    warning: '⚠️',
    critical: '🚨'
  }[toast.severity];
</script>

<div 
  class="fixed top-4 right-4 z-50 max-w-sm w-full bg-white border-l-4 rounded-lg shadow-lg cursor-pointer transition-all duration-300 hover:shadow-xl {severityClasses}"
  on:click={handleClick}
  on:keydown={(e) => e.key === 'Enter' && handleClick()}
  role="button"
  tabindex="0"
>
  <div class="p-4">
    <div class="flex items-start">
      <div class="flex-shrink-0">
        <span class="text-lg" role="img" aria-label={toast.severity}>
          {severityIcon}
        </span>
      </div>
      
      <div class="ml-3 flex-1">
        <div class="flex items-center justify-between">
          <p class="text-sm font-medium">
            {toast.severity.toUpperCase()} Alert
          </p>
          <button
            on:click|stopPropagation={handleClose}
            class="ml-2 text-gray-400 hover:text-gray-600 focus:outline-none focus:text-gray-600"
            aria-label="Close notification"
          >
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        
        <p class="mt-1 text-sm">
          {toast.message}
        </p>
        
        <p class="mt-2 text-xs font-medium">
          Patient: {toast.patientName}
        </p>
        
        <p class="mt-1 text-xs text-gray-500">
          {new Date(toast.timestamp).toLocaleTimeString()}
        </p>
      </div>
    </div>
  </div>
</div>