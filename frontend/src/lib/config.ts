/**
 * Configuração centralizada da aplicação
 * Usa variáveis de ambiente do SvelteKit (PUBLIC_*)
 */

// Detectar ambiente
const isDevelopment = import.meta.env.DEV;
const isProduction = import.meta.env.PROD;

// URLs base da API
export const API_BASE_URL = import.meta.env.PUBLIC_API_URL ||
  (isDevelopment
    ? 'http://localhost:8080/api'
    : 'https://orthotrack.alexptech.com/api');

export const WS_BASE_URL = import.meta.env.PUBLIC_WS_URL ||
  (isDevelopment
    ? 'ws://localhost:8080/ws'
    : 'wss://orthotrack.alexptech.com/ws');

// URL completa da API v1
export const API_V1_URL = `${API_BASE_URL}/v1`;

// Configurações da aplicação
export const config = {
  // URLs
  api: {
    baseUrl: API_BASE_URL,
    v1Url: API_V1_URL,
    wsUrl: WS_BASE_URL,
  },
  
  // Ambiente
  env: {
    isDevelopment,
    isProduction,
    mode: import.meta.env.MODE,
  },
  
  // Timeouts
  timeouts: {
    request: 30000, // 30 segundos
    websocket: 5000,
  },
  
  // Outras configurações
  app: {
    name: 'OrthoTrack IoT Platform',
    version: '3.0.0',
    origin: isProduction
      ? 'https://orthotrack.alexptech.com'
      : 'http://localhost:3000',
  }
} as const;

// Helper para construir URLs
export function buildApiUrl(path: string): string {
  const cleanPath = path.startsWith('/') ? path : `/${path}`;
  return `${API_V1_URL}${cleanPath}`;
}

// Log de configuração (apenas em dev)
if (isDevelopment) {
  console.log('🔧 App Configuration:', config);
}

export default config;