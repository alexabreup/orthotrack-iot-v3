<script lang="ts">
  import { toasts, removeToast, handleToastClick } from '$lib/stores/toast.store';
  import ToastNotification from './ToastNotification.svelte';
  
  function onToastClick(event: CustomEvent<{ patientId: string }>) {
    handleToastClick(event.detail.patientId);
  }
  
  function onToastRemove(event: CustomEvent<{ id: string }>) {
    removeToast(event.detail.id);
  }
</script>

<!-- Toast container positioned in top-right corner -->
<div class="fixed top-4 right-4 z-50 space-y-2 pointer-events-none">
  {#each $toasts as toast (toast.id)}
    <div class="pointer-events-auto">
      <ToastNotification 
        {toast} 
        on:click={onToastClick}
        on:remove={onToastRemove}
      />
    </div>
  {/each}
</div>