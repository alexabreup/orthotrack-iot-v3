import { App } from '@capacitor/app';
import { Network } from '@capacitor/network';
import { Preferences } from '@capacitor/preferences';
import { StatusBar, Style } from '@capacitor/status-bar';
import { SplashScreen } from '@capacitor/splash-screen';
import { Toast } from '@capacitor/toast';
import { Capacitor } from '@capacitor/core';
import { EdgeNodeService } from './services/edge-node.service';
import { BLEService } from './services/ble.service';
import { APIService } from './services/api.service';
import { Logger } from './utils/logger';

// Inicializar Capacitor
const platform = Capacitor.getPlatform();
console.log('Platform:', platform);

// Configurações
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://10.0.2.2:8080';
const MQTT_BROKER_URL = import.meta.env.VITE_MQTT_BROKER_URL || 'tcp://10.0.2.2:1883';

// Serviços
const logger = new Logger();
const apiService = new APIService(API_BASE_URL, logger);
const bleService = new BLEService(logger);
const edgeNodeService = new EdgeNodeService(apiService, bleService, logger);

// Elementos DOM
const scanBtn = document.getElementById('scan-btn') as HTMLButtonElement;
const refreshBtn = document.getElementById('refresh-btn') as HTMLButtonElement;
const clearLogsBtn = document.getElementById('clear-logs-btn') as HTMLButtonElement;
const deviceList = document.getElementById('device-list') as HTMLUListElement;
const logContainer = document.getElementById('log-container') as HTMLDivElement;
const backendStatus = document.getElementById('backend-status') as HTMLDivElement;
const bleStatus = document.getElementById('ble-status') as HTMLDivElement;
const syncStatus = document.getElementById('sync-status') as HTMLDivElement;

// Inicialização
async function init() {
    logger.info('Inicializando OrthoTrack Edge Node...');
    
    try {
        // Configurar Status Bar
        if (Capacitor.isNativePlatform()) {
            await StatusBar.setStyle({ style: Style.Light });
            await StatusBar.setBackgroundColor({ color: '#ffffff' });
        }
        
        // Esconder Splash Screen
        await SplashScreen.hide();
        
        // Verificar conectividade
        await checkConnectivity();
        
        // Verificar backend
        await checkBackend();
        
        // Verificar Bluetooth
        await checkBluetooth();
        
        // Event listeners
        setupEventListeners();
        
        // Network status listener
        Network.addListener('networkStatusChange', (status) => {
            logger.info(`Status da rede: ${status.connected ? 'Conectado' : 'Desconectado'}`);
            updateBackendStatus();
        });
        
        // App state listeners
        App.addListener('appStateChange', ({ isActive }) => {
            logger.info(`App ${isActive ? 'ativo' : 'em background'}`);
        });
        
        logger.success('Sistema inicializado com sucesso!');
        
    } catch (error) {
        logger.error(`Erro na inicialização: ${error}`);
        await Toast.show({
            text: 'Erro ao inicializar o sistema',
            duration: 'long'
        });
    }
}

async function checkConnectivity() {
    const status = await Network.getStatus();
    logger.info(`Rede: ${status.connected ? 'Conectado' : 'Desconectado'} (${status.connectionType})`);
}

async function checkBackend() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/v1/health`);
        if (response.ok) {
            const data = await response.json();
            logger.success('Backend conectado!');
            backendStatus.querySelector('.value')!.textContent = 'Online';
            backendStatus.classList.add('online');
            backendStatus.classList.remove('offline');
        } else {
            throw new Error('Backend não respondeu corretamente');
        }
    } catch (error) {
        logger.error('Backend offline');
        backendStatus.querySelector('.value')!.textContent = 'Offline';
        backendStatus.classList.add('offline');
        backendStatus.classList.remove('online');
    }
}

async function checkBluetooth() {
    try {
        // Verificar se Web Bluetooth está disponível
        if (navigator.bluetooth) {
            logger.info('Bluetooth Web API disponível');
            bleStatus.querySelector('.value')!.textContent = 'Disponível';
            bleStatus.classList.add('online');
        } else {
            logger.warning('Bluetooth Web API não disponível');
            bleStatus.querySelector('.value')!.textContent = 'Indisponível';
            bleStatus.classList.add('offline');
        }
    } catch (error) {
        logger.error('Erro ao verificar Bluetooth');
        bleStatus.querySelector('.value')!.textContent = 'Erro';
        bleStatus.classList.add('offline');
    }
}

function setupEventListeners() {
    scanBtn.addEventListener('click', async () => {
        scanBtn.disabled = true;
        scanBtn.innerHTML = '<span class="loading"></span> Escaneando...';
        
        try {
            await edgeNodeService.scanDevices();
            await updateDeviceList();
            await Toast.show({
                text: 'Escaneamento concluído',
                duration: 'short'
            });
        } catch (error) {
            logger.error(`Erro ao escanear: ${error}`);
            await Toast.show({
                text: 'Erro ao escanear dispositivos',
                duration: 'long'
            });
        } finally {
            scanBtn.disabled = false;
            scanBtn.textContent = '🔍 Escanear Dispositivos';
        }
    });
    
    refreshBtn.addEventListener('click', async () => {
        await checkBackend();
        await updateDeviceList();
        await Toast.show({
            text: 'Atualizado',
            duration: 'short'
        });
    });
    
    clearLogsBtn.addEventListener('click', () => {
        logContainer.innerHTML = '';
        logger.info('Logs limpos');
    });
}

async function updateDeviceList() {
    const devices = await edgeNodeService.getDevices();
    
    if (devices.length === 0) {
        deviceList.innerHTML = `
            <li style="text-align: center; padding: 20px; color: #666;">
                Nenhum dispositivo encontrado. Clique em "Escanear Dispositivos" para começar.
            </li>
        `;
        return;
    }
    
    deviceList.innerHTML = devices.map(device => `
        <li class="device-item">
            <div class="device-info">
                <div class="device-name">${device.name || 'Dispositivo Desconhecido'}</div>
                <div class="device-id">${device.id}</div>
            </div>
            <div>
                <span class="device-status ${device.connected ? 'connected' : 'disconnected'}">
                    ${device.connected ? 'Conectado' : 'Desconectado'}
                </span>
                <button class="btn btn-sm" data-device-id="${device.id}">
                    ${device.connected ? 'Desconectar' : 'Conectar'}
                </button>
            </div>
        </li>
    `).join('');
    
    // Adicionar listeners aos botões
    deviceList.querySelectorAll('button').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            const deviceId = (e.target as HTMLButtonElement).dataset.deviceId;
            if (deviceId) {
                await handleDeviceConnection(deviceId);
            }
        });
    });
}

async function handleDeviceConnection(deviceId: string) {
    try {
        const device = await edgeNodeService.getDevice(deviceId);
        if (device?.connected) {
            await edgeNodeService.disconnectDevice(deviceId);
        } else {
            await edgeNodeService.connectDevice(deviceId);
        }
        await updateDeviceList();
    } catch (error) {
        logger.error(`Erro ao conectar/desconectar: ${error}`);
    }
}

async function updateBackendStatus() {
    await checkBackend();
}

// Logger customizado que atualiza a UI
class UILogger {
    private logger: Logger;
    
    constructor() {
        this.logger = logger;
    }
    
    private addLogEntry(level: string, message: string) {
        const entry = document.createElement('div');
        entry.className = `log-entry ${level}`;
        entry.textContent = `[${new Date().toLocaleTimeString()}] [${level.toUpperCase()}] ${message}`;
        logContainer.appendChild(entry);
        logContainer.scrollTop = logContainer.scrollHeight;
    }
    
    info(message: string) {
        this.logger.info(message);
        this.addLogEntry('info', message);
    }
    
    success(message: string) {
        this.logger.info(message);
        this.addLogEntry('success', message);
    }
    
    error(message: string) {
        this.logger.error(message);
        this.addLogEntry('error', message);
    }
    
    warning(message: string) {
        this.logger.warning(message);
        this.addLogEntry('warning', message);
    }
}

// Substituir logger global
Object.assign(logger, new UILogger());

// Inicializar quando DOM estiver pronto
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}






