# Frontend Technical Specifications - SvelteKit Dashboard

## 🎨 Arquitetura Frontend

### Stack Tecnológico
- **Framework**: SvelteKit 1.27+
- **Language**: TypeScript
- **Styling**: Tailwind CSS + shadcn/ui components
- **Charts**: Chart.js + chartjs-adapter-date-fns
- **Tables**: @tanstack/svelte-table
- **Icons**: Lucide Svelte
- **Notifications**: Svelte Sonner / Svelte French Toast
- **Build Tool**: Vite
- **Package Manager**: npm/pnpm

### Estrutura do Projeto
```
frontend/
├── src/
│   ├── app.html                 # HTML template
│   ├── app.css                  # Global styles
│   ├── routes/                  # Pages and API routes
│   │   ├── +layout.svelte       # Root layout
│   │   ├── +page.svelte         # Dashboard home
│   │   ├── auth/                # Authentication pages
│   │   ├── patients/            # Patient management
│   │   ├── devices/             # Device management
│   │   ├── analytics/           # Analytics dashboard
│   │   ├── alerts/              # Alerts management
│   │   └── settings/            # Application settings
│   ├── lib/                     # Shared libraries
│   │   ├── components/          # Reusable UI components
│   │   ├── stores/              # Svelte stores
│   │   ├── services/            # API services
│   │   ├── utils/               # Utility functions
│   │   ├── types/               # TypeScript types
│   │   └── constants/           # Application constants
│   └── static/                  # Static assets
│       ├── icons/
│       ├── images/
│       └── favicon.ico
├── tests/                       # Test files
├── docs/                        # Component documentation
└── tailwind.config.js           # Tailwind configuration
```

---

## 🧩 Componentes Principais

### Layout e Navegação

#### MainLayout.svelte
```svelte
<script lang="ts">
  import { page } from '$app/stores';
  import { user } from '$lib/stores/auth';
  import Sidebar from '$lib/components/Sidebar.svelte';
  import Header from '$lib/components/Header.svelte';
  import Breadcrumbs from '$lib/components/Breadcrumbs.svelte';
  
  $: currentPath = $page.url.pathname;
</script>

<div class="min-h-screen bg-gray-50">
  <Sidebar {currentPath} />
  
  <div class="lg:pl-64">
    <Header />
    
    <main class="py-6">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <Breadcrumbs />
        <slot />
      </div>
    </main>
  </div>
</div>
```

#### Sidebar.svelte
```svelte
<script lang="ts">
  import { Menu, Users, Activity, AlertTriangle, Settings } from 'lucide-svelte';
  
  const navigation = [
    { name: 'Dashboard', href: '/', icon: Activity },
    { name: 'Pacientes', href: '/patients', icon: Users },
    { name: 'Dispositivos', href: '/devices', icon: Menu },
    { name: 'Alertas', href: '/alerts', icon: AlertTriangle },
    { name: 'Configurações', href: '/settings', icon: Settings },
  ];
  
  export let currentPath: string;
</script>

<div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-64 lg:flex-col">
  <div class="flex grow flex-col gap-y-5 overflow-y-auto bg-white px-6 shadow-xl">
    <!-- Sidebar content -->
    <div class="flex h-16 shrink-0 items-center">
      <img class="h-8 w-auto" src="/logo.svg" alt="OrthoTrack" />
    </div>
    
    <nav class="flex flex-1 flex-col">
      <ul role="list" class="flex flex-1 flex-col gap-y-7">
        <li>
          <ul role="list" class="-mx-2 space-y-1">
            {#each navigation as item}
              <li>
                <a
                  href={item.href}
                  class:bg-gray-50={currentPath === item.href}
                  class:text-blue-700={currentPath === item.href}
                  class="group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6"
                >
                  <svelte:component this={item.icon} class="h-6 w-6 shrink-0" />
                  {item.name}
                </a>
              </li>
            {/each}
          </ul>
        </li>
      </ul>
    </nav>
  </div>
</div>
```

### Dashboard Components

#### DashboardStats.svelte
```svelte
<script lang="ts">
  import { onMount } from 'svelte';
  import { dashboardService } from '$lib/services/dashboard';
  import type { DashboardStats } from '$lib/types/dashboard';
  
  let stats: DashboardStats | null = null;
  let loading = true;
  
  onMount(async () => {
    try {
      stats = await dashboardService.getStats();
    } catch (error) {
      console.error('Error loading stats:', error);
    } finally {
      loading = false;
    }
  });
  
  const statCards = [
    { name: 'Total Pacientes', value: stats?.totalPatients || 0, change: '+2.1%' },
    { name: 'Dispositivos Ativos', value: stats?.activeDevices || 0, change: '+5.4%' },
    { name: 'Compliance Médio', value: `${stats?.avgCompliance || 0}%`, change: '+1.2%' },
    { name: 'Alertas Pendentes', value: stats?.pendingAlerts || 0, change: '-3.1%' },
  ];
</script>

<div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
  {#each statCards as stat}
    <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
      <dt class="truncate text-sm font-medium text-gray-500">{stat.name}</dt>
      <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
        {#if loading}
          <div class="h-8 w-16 animate-pulse rounded bg-gray-200"></div>
        {:else}
          {stat.value}
        {/if}
      </dd>
      <div class="mt-2 flex items-baseline text-sm">
        <span class="text-green-600">{stat.change}</span>
        <span class="ml-1 text-gray-500">vs. mês anterior</span>
      </div>
    </div>
  {/each}
</div>
```

#### ComplianceChart.svelte
```svelte
<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import Chart from 'chart.js/auto';
  import 'chartjs-adapter-date-fns';
  import { chartService } from '$lib/services/chart';
  
  export let patientId: number | null = null;
  export let period: string = '7d';
  
  let chartCanvas: HTMLCanvasElement;
  let chartInstance: Chart;
  let data: any[] = [];
  
  onMount(async () => {
    await loadData();
    initChart();
  });
  
  onDestroy(() => {
    if (chartInstance) {
      chartInstance.destroy();
    }
  });
  
  async function loadData() {
    try {
      data = await chartService.getComplianceData(patientId, period);
    } catch (error) {
      console.error('Error loading chart data:', error);
    }
  }
  
  function initChart() {
    if (!chartCanvas) return;
    
    chartInstance = new Chart(chartCanvas, {
      type: 'line',
      data: {
        datasets: [{
          label: 'Compliance (%)',
          data: data,
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          tension: 0.1,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            type: 'time',
            time: {
              unit: 'day'
            }
          },
          y: {
            beginAtZero: true,
            max: 100,
            ticks: {
              callback: (value) => `${value}%`
            }
          }
        }
      }
    });
  }
  
  $: if (patientId !== null || period) {
    loadData().then(() => {
      if (chartInstance) {
        chartInstance.data.datasets[0].data = data;
        chartInstance.update();
      }
    });
  }
</script>

<div class="relative h-80 w-full">
  <canvas bind:this={chartCanvas}></canvas>
</div>
```

### Gerenciamento de Pacientes

#### PatientTable.svelte
```svelte
<script lang="ts">
  import { createTable, getCoreRowModel, getPaginationRowModel } from '@tanstack/svelte-table';
  import { writable } from 'svelte/store';
  import type { Patient } from '$lib/types/patient';
  import PatientStatusBadge from './PatientStatusBadge.svelte';
  import ComplianceMeter from './ComplianceMeter.svelte';
  
  export let patients: Patient[] = [];
  
  const data = writable(patients);
  
  const columns = [
    {
      accessorKey: 'name',
      header: 'Nome',
      cell: (info: any) => info.getValue(),
    },
    {
      accessorKey: 'external_id',
      header: 'ID AACD',
      cell: (info: any) => info.getValue(),
    },
    {
      accessorKey: 'age',
      header: 'Idade',
      cell: (info: any) => `${info.getValue()} anos`,
    },
    {
      accessorKey: 'compliance_score',
      header: 'Compliance',
      cell: (info: any) => {
        return {
          component: ComplianceMeter,
          props: { score: info.getValue() }
        };
      },
    },
    {
      accessorKey: 'status',
      header: 'Status',
      cell: (info: any) => {
        return {
          component: PatientStatusBadge,
          props: { status: info.getValue() }
        };
      },
    },
    {
      id: 'actions',
      header: 'Ações',
      cell: () => ({
        component: PatientActions,
        props: {}
      }),
    },
  ];
  
  const table = createTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
  });
  
  $: data.set(patients);
</script>

<div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
  <table class="min-w-full divide-y divide-gray-300">
    <thead class="bg-gray-50">
      {#each $table.getHeaderGroups() as headerGroup}
        <tr>
          {#each headerGroup.headers as header}
            <th class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
              {header.isPlaceholder ? '' : header.column.columnDef.header}
            </th>
          {/each}
        </tr>
      {/each}
    </thead>
    <tbody class="divide-y divide-gray-200 bg-white">
      {#each $table.getRowModel().rows as row}
        <tr class="hover:bg-gray-50">
          {#each row.getVisibleCells() as cell}
            <td class="whitespace-nowrap px-6 py-4 text-sm text-gray-900">
              {#if cell.column.columnDef.cell?.component}
                <svelte:component 
                  this={cell.column.columnDef.cell.component} 
                  {...cell.column.columnDef.cell.props}
                />
              {:else}
                {cell.getValue()}
              {/if}
            </td>
          {/each}
        </tr>
      {/each}
    </tbody>
  </table>
  
  <!-- Pagination -->
  <div class="flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3">
    <div class="flex flex-1 justify-between sm:hidden">
      <button
        on:click={() => table.previousPage()}
        disabled={!table.getCanPreviousPage()}
        class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
      >
        Anterior
      </button>
      <button
        on:click={() => table.nextPage()}
        disabled={!table.getCanNextPage()}
        class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
      >
        Próximo
      </button>
    </div>
  </div>
</div>
```

---

## 🏪 Stores (Gerenciamento de Estado)

### Auth Store
```typescript
// lib/stores/auth.ts
import { writable } from 'svelte/store';
import type { User } from '$lib/types/auth';

interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}

function createAuthStore() {
  const { subscribe, set, update } = writable<AuthState>({
    user: null,
    isAuthenticated: false,
    isLoading: true,
  });

  return {
    subscribe,
    login: async (credentials: LoginCredentials) => {
      update(state => ({ ...state, isLoading: true }));
      try {
        const response = await authService.login(credentials);
        set({
          user: response.user,
          isAuthenticated: true,
          isLoading: false,
        });
        return response;
      } catch (error) {
        set({
          user: null,
          isAuthenticated: false,
          isLoading: false,
        });
        throw error;
      }
    },
    logout: async () => {
      await authService.logout();
      set({
        user: null,
        isAuthenticated: false,
        isLoading: false,
      });
    },
    checkAuth: async () => {
      try {
        const user = await authService.getCurrentUser();
        set({
          user,
          isAuthenticated: !!user,
          isLoading: false,
        });
      } catch {
        set({
          user: null,
          isAuthenticated: false,
          isLoading: false,
        });
      }
    },
  };
}

export const auth = createAuthStore();
```

### Real-time Data Store
```typescript
// lib/stores/realtime.ts
import { writable } from 'svelte/store';
import { browser } from '$app/environment';

interface RealtimeData {
  deviceStatuses: Map<number, DeviceStatus>;
  activeAlerts: Alert[];
  lastUpdate: Date | null;
}

function createRealtimeStore() {
  const { subscribe, set, update } = writable<RealtimeData>({
    deviceStatuses: new Map(),
    activeAlerts: [],
    lastUpdate: null,
  });

  let ws: WebSocket | null = null;

  const connect = () => {
    if (!browser || ws?.readyState === WebSocket.OPEN) return;

    ws = new WebSocket('ws://localhost:8080/ws');
    
    ws.onopen = () => {
      console.log('WebSocket connected');
    };
    
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      
      switch (data.type) {
        case 'device_status':
          update(state => {
            state.deviceStatuses.set(data.device_id, data.status);
            return { ...state, lastUpdate: new Date() };
          });
          break;
        case 'alert':
          update(state => ({
            ...state,
            activeAlerts: [...state.activeAlerts, data.alert],
            lastUpdate: new Date(),
          }));
          break;
      }
    };
    
    ws.onclose = () => {
      console.log('WebSocket disconnected, reconnecting...');
      setTimeout(connect, 5000);
    };
  };

  const disconnect = () => {
    ws?.close();
    ws = null;
  };

  return {
    subscribe,
    connect,
    disconnect,
    sendMessage: (message: any) => {
      if (ws?.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(message));
      }
    },
  };
}

export const realtime = createRealtimeStore();
```

---

## 🔌 Services (API Integration)

### Base API Service
```typescript
// lib/services/api.ts
import { auth } from '$lib/stores/auth';
import { goto } from '$app/navigation';
import { get } from 'svelte/store';

class ApiService {
  private baseURL = 'http://localhost:8080/api/v1';

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const authState = get(auth);
    const token = authState.user?.token;

    const config: RequestInit = {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
        ...options.headers,
      },
    };

    const response = await fetch(`${this.baseURL}${endpoint}`, config);

    if (response.status === 401) {
      auth.logout();
      goto('/auth/login');
      throw new Error('Unauthorized');
    }

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Request failed');
    }

    return response.json();
  }

  get<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  post<T>(endpoint: string, data: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  put<T>(endpoint: string, data: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }
}

export const apiService = new ApiService();
```

### Patient Service
```typescript
// lib/services/patient.ts
import { apiService } from './api';
import type { Patient, CreatePatientRequest, UpdatePatientRequest } from '$lib/types/patient';

class PatientService {
  async getPatients(params?: {
    page?: number;
    limit?: number;
    search?: string;
  }): Promise<{ patients: Patient[]; total: number }> {
    const searchParams = new URLSearchParams();
    if (params?.page) searchParams.set('page', params.page.toString());
    if (params?.limit) searchParams.set('limit', params.limit.toString());
    if (params?.search) searchParams.set('search', params.search);

    return apiService.get(`/patients?${searchParams}`);
  }

  async getPatient(id: number): Promise<Patient> {
    return apiService.get(`/patients/${id}`);
  }

  async createPatient(data: CreatePatientRequest): Promise<Patient> {
    return apiService.post('/patients', data);
  }

  async updatePatient(id: number, data: UpdatePatientRequest): Promise<Patient> {
    return apiService.put(`/patients/${id}`, data);
  }

  async deletePatient(id: number): Promise<void> {
    return apiService.delete(`/patients/${id}`);
  }

  async getComplianceData(id: number, period: string = '30d') {
    return apiService.get(`/patients/${id}/compliance?period=${period}`);
  }

  async getUsageSessions(id: number, limit: number = 50) {
    return apiService.get(`/patients/${id}/sessions?limit=${limit}`);
  }
}

export const patientService = new PatientService();
```

---

## 🎯 TypeScript Types

### Core Types
```typescript
// lib/types/patient.ts
export interface Patient {
  id: number;
  external_id: string;
  name: string;
  date_of_birth: string;
  gender: 'M' | 'F';
  cpf: string;
  email: string;
  phone: string;
  guardian_name?: string;
  guardian_phone?: string;
  
  // Medical Info
  diagnosis_code: string;
  severity_level: number;
  prescription_hours: number;
  treatment_start: string;
  treatment_end?: string;
  
  // Computed fields
  age: number;
  compliance_score: number;
  status: 'active' | 'inactive' | 'completed';
  
  // Relationships
  institution_id: number;
  institution: Institution;
  braces: Brace[];
  
  created_at: string;
  updated_at: string;
}

export interface CreatePatientRequest {
  external_id: string;
  name: string;
  date_of_birth: string;
  gender: 'M' | 'F';
  cpf: string;
  email: string;
  phone: string;
  guardian_name?: string;
  guardian_phone?: string;
  diagnosis_code: string;
  severity_level: number;
  prescription_hours: number;
  treatment_start: string;
  institution_id: number;
}

export type UpdatePatientRequest = Partial<CreatePatientRequest>;
```

```typescript
// lib/types/device.ts
export interface Brace {
  id: number;
  serial_number: string;
  device_id: string;
  model: string;
  version: string;
  patient_id: number;
  patient?: Patient;
  status: 'active' | 'inactive' | 'maintenance';
  battery_level: number;
  last_heartbeat: string;
  firmware_version: string;
  calibration_data: Record<string, any>;
  last_calibration: string;
  created_at: string;
  updated_at: string;
}

export interface DeviceStatus {
  id: number;
  online: boolean;
  battery_level: number;
  last_seen: string;
  current_session?: {
    started_at: string;
    duration: number;
    compliance_score: number;
  };
}
```

```typescript
// lib/types/alert.ts
export interface Alert {
  id: number;
  type: 'battery_low' | 'compliance_low' | 'device_offline' | 'anomaly_detected';
  severity: 'info' | 'warning' | 'error' | 'critical';
  title: string;
  message: string;
  brace_id?: number;
  patient_id?: number;
  status: 'open' | 'acknowledged' | 'resolved' | 'dismissed';
  acknowledged_by?: number;
  acknowledged_at?: string;
  resolved_at?: string;
  metadata: Record<string, any>;
  created_at: string;
  updated_at: string;
}
```

---

## 🎨 Styling e Tema

### Tailwind Configuration
```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          900: '#1e3a8a',
        },
        success: {
          50: '#f0fdf4',
          500: '#22c55e',
          600: '#16a34a',
        },
        warning: {
          50: '#fffbeb',
          500: '#f59e0b',
          600: '#d97706',
        },
        danger: {
          50: '#fef2f2',
          500: '#ef4444',
          600: '#dc2626',
        },
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'bounce-slow': 'bounce 2s infinite',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

### Global Styles
```css
/* app.css */
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';

@layer base {
  html {
    font-family: 'Inter', system-ui, sans-serif;
  }
  
  body {
    @apply antialiased;
  }
}

@layer components {
  .btn {
    @apply inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2;
  }
  
  .btn-primary {
    @apply btn text-white bg-primary-600 hover:bg-primary-700 focus:ring-primary-500;
  }
  
  .btn-secondary {
    @apply btn text-gray-700 bg-white hover:bg-gray-50 border-gray-300 focus:ring-primary-500;
  }
  
  .card {
    @apply bg-white overflow-hidden shadow rounded-lg;
  }
  
  .card-header {
    @apply px-4 py-5 border-b border-gray-200 sm:px-6;
  }
  
  .card-body {
    @apply px-4 py-5 sm:p-6;
  }
}

@layer utilities {
  .text-balance {
    text-wrap: balance;
  }
}
```

---

## 🧪 Testing

### Component Testing
```typescript
// tests/components/PatientTable.test.ts
import { render, screen } from '@testing-library/svelte';
import PatientTable from '$lib/components/PatientTable.svelte';
import type { Patient } from '$lib/types/patient';

const mockPatients: Patient[] = [
  {
    id: 1,
    name: 'João Silva',
    external_id: 'AACD001',
    age: 15,
    compliance_score: 85,
    status: 'active',
    // ... other fields
  },
];

describe('PatientTable', () => {
  it('renders patient data correctly', () => {
    render(PatientTable, { patients: mockPatients });
    
    expect(screen.getByText('João Silva')).toBeInTheDocument();
    expect(screen.getByText('AACD001')).toBeInTheDocument();
    expect(screen.getByText('15 anos')).toBeInTheDocument();
  });

  it('shows empty state when no patients', () => {
    render(PatientTable, { patients: [] });
    
    expect(screen.getByText('Nenhum paciente encontrado')).toBeInTheDocument();
  });
});
```

### E2E Testing
```typescript
// tests/e2e/patient-management.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Patient Management', () => {
  test('should create a new patient', async ({ page }) => {
    await page.goto('/patients');
    
    await page.click('[data-testid=new-patient-button]');
    await page.fill('[data-testid=patient-name]', 'João Silva');
    await page.fill('[data-testid=patient-cpf]', '123.456.789-00');
    await page.fill('[data-testid=patient-email]', 'joao@example.com');
    
    await page.click('[data-testid=save-button]');
    
    await expect(page.locator('text=Paciente criado com sucesso')).toBeVisible();
  });
});
```

---

## 🚀 Build e Deploy

### Build Configuration
```typescript
// vite.config.js
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [sveltekit()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
  build: {
    target: 'es2020',
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor': ['svelte', '@sveltejs/kit'],
          'charts': ['chart.js'],
          'ui': ['lucide-svelte', '@tanstack/svelte-table'],
        },
      },
    },
  },
});
```

### Environment Configuration
```typescript
// src/lib/config.ts
export const config = {
  apiUrl: import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1',
  wsUrl: import.meta.env.VITE_WS_URL || 'ws://localhost:8080/ws',
  environment: import.meta.env.MODE,
  isDev: import.meta.env.DEV,
  isProd: import.meta.env.PROD,
};
```

---

**Documentação Técnica - Frontend SvelteKit**  
**Versão**: 1.0  
**Última Atualização**: 2024-12-03