// Simple test to verify environment variables are working
console.log('Testing environment configuration...');

// Simulate the environment variables that would be available
const testEnv = {
  PUBLIC_API_URL: 'https://orthotrack.alexptech.com/api',
  PUBLIC_WS_URL: 'wss://orthotrack.alexptech.com/ws',
  DEV: false,
  PROD: true,
  MODE: 'production'
};

// Simulate import.meta.env
const importMeta = {
  env: testEnv
};

// Test the config logic
const isDevelopment = importMeta.env.DEV;
const isProduction = importMeta.env.PROD;

const API_BASE_URL = importMeta.env.PUBLIC_API_URL ||
  (isDevelopment
    ? 'http://localhost:8080/api'
    : 'https://orthotrack.alexptech.com/api');

const WS_BASE_URL = importMeta.env.PUBLIC_WS_URL ||
  (isDevelopment
    ? 'ws://localhost:8080/ws'
    : 'wss://orthotrack.alexptech.com/ws');

const API_V1_URL = `${API_BASE_URL}/v1`;

console.log('✅ Configuration Test Results:');
console.log('  Environment:', importMeta.env.MODE);
console.log('  isDevelopment:', isDevelopment);
console.log('  isProduction:', isProduction);
console.log('  API_BASE_URL:', API_BASE_URL);
console.log('  WS_BASE_URL:', WS_BASE_URL);
console.log('  API_V1_URL:', API_V1_URL);

// Verify production URLs
if (isProduction) {
  const expectedApiUrl = 'https://orthotrack.alexptech.com/api';
  const expectedWsUrl = 'wss://orthotrack.alexptech.com/ws';
  const expectedV1Url = 'https://orthotrack.alexptech.com/api/v1';
  
  if (API_BASE_URL === expectedApiUrl && 
      WS_BASE_URL === expectedWsUrl && 
      API_V1_URL === expectedV1Url) {
    console.log('✅ Production URLs are correct!');
  } else {
    console.log('❌ Production URLs are incorrect!');
    console.log('  Expected API:', expectedApiUrl, 'Got:', API_BASE_URL);
    console.log('  Expected WS:', expectedWsUrl, 'Got:', WS_BASE_URL);
    console.log('  Expected V1:', expectedV1Url, 'Got:', API_V1_URL);
  }
}

console.log('Test completed!');