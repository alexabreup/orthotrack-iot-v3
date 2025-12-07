import { Logger } from '../utils/logger';
import { ESP32Device } from '../types/device';

export class BLEService {
    private logger: Logger;
    private devices: Map<string, ESP32Device> = new Map();
    private connectedDevices: Map<string, BluetoothRemoteGATTServer> = new Map();

    // UUIDs do serviço ESP32 (exemplo - ajustar conforme firmware)
    private readonly ESP32_SERVICE_UUID = '12345678-1234-1234-1234-123456789abc';
    private readonly ESP32_CHAR_TELEMETRY_UUID = '12345678-1234-1234-1234-123456789abd';
    private readonly ESP32_CHAR_COMMAND_UUID = '12345678-1234-1234-1234-123456789abe';

    constructor(logger: Logger) {
        this.logger = logger;
    }

    async isAvailable(): Promise<boolean> {
        return 'bluetooth' in navigator;
    }

    async scanDevices(): Promise<ESP32Device[]> {
        if (!await this.isAvailable()) {
            throw new Error('Bluetooth não está disponível neste dispositivo');
        }

        this.logger.info('Iniciando escaneamento BLE...');

        try {
            const device = await navigator.bluetooth.requestDevice({
                filters: [
                    { namePrefix: 'ESP32' },
                    { namePrefix: 'OrthoTrack' },
                    { services: [this.ESP32_SERVICE_UUID] },
                ],
                optionalServices: [this.ESP32_SERVICE_UUID],
            });

            const esp32Device: ESP32Device = {
                id: device.id,
                name: device.name || 'ESP32 Device',
                address: '', // Não disponível via Web Bluetooth API
                connected: false,
            };

            this.devices.set(device.id, esp32Device);
            this.logger.success(`Dispositivo encontrado: ${esp32Device.name} (${device.id})`);

            return Array.from(this.devices.values());
        } catch (error: any) {
            if (error.name === 'NotFoundError') {
                this.logger.warning('Nenhum dispositivo encontrado');
                return [];
            }
            throw error;
        }
    }

    async connectDevice(deviceId: string): Promise<boolean> {
        const device = this.devices.get(deviceId);
        if (!device) {
            throw new Error(`Dispositivo ${deviceId} não encontrado`);
        }

        if (this.connectedDevices.has(deviceId)) {
            this.logger.warning(`Dispositivo ${deviceId} já está conectado`);
            return true;
        }

        try {
            this.logger.info(`Conectando ao dispositivo ${device.name}...`);

            // Nota: Web Bluetooth API requer que o usuário selecione o dispositivo
            // Para uso contínuo, você precisaria de um plugin Capacitor customizado
            const bluetoothDevice = await navigator.bluetooth.requestDevice({
                filters: [{ name: device.name }],
                optionalServices: [this.ESP32_SERVICE_UUID],
            });

            if (!bluetoothDevice.gatt) {
                throw new Error('GATT não disponível');
            }

            const server = await bluetoothDevice.gatt.connect();
            this.connectedDevices.set(deviceId, server);
            device.connected = true;

            this.logger.success(`Conectado ao dispositivo ${device.name}`);

            // Iniciar leitura de características
            this.startReadingCharacteristics(deviceId, server);

            return true;
        } catch (error) {
            this.logger.error(`Erro ao conectar: ${error}`);
            device.connected = false;
            return false;
        }
    }

    async disconnectDevice(deviceId: string): Promise<boolean> {
        const server = this.connectedDevices.get(deviceId);
        if (!server) {
            return false;
        }

        try {
            if (server.connected) {
                server.disconnect();
            }
            this.connectedDevices.delete(deviceId);

            const device = this.devices.get(deviceId);
            if (device) {
                device.connected = false;
            }

            this.logger.info(`Desconectado do dispositivo ${deviceId}`);
            return true;
        } catch (error) {
            this.logger.error(`Erro ao desconectar: ${error}`);
            return false;
        }
    }

    private async startReadingCharacteristics(deviceId: string, server: BluetoothRemoteGATTServer) {
        try {
            const service = await server.getPrimaryService(this.ESP32_SERVICE_UUID);
            const characteristic = await service.getCharacteristic(this.ESP32_CHAR_TELEMETRY_UUID);

            // Ler valor inicial
            const value = await characteristic.readValue();
            this.handleTelemetryData(deviceId, value);

            // Escutar notificações
            await characteristic.startNotifications();
            characteristic.addEventListener('characteristicvaluechanged', (event) => {
                const target = event.target as BluetoothRemoteGATTCharacteristic;
                if (target.value) {
                    this.handleTelemetryData(deviceId, target.value);
                }
            });

            this.logger.info(`Leitura de telemetria iniciada para ${deviceId}`);
        } catch (error) {
            this.logger.error(`Erro ao iniciar leitura: ${error}`);
        }
    }

    private handleTelemetryData(deviceId: string, value: DataView) {
        try {
            // Decodificar dados (ajustar conforme protocolo do ESP32)
            const textDecoder = new TextDecoder();
            const data = JSON.parse(textDecoder.decode(value));

            this.logger.debug(`Telemetria recebida de ${deviceId}:`, data);

            // Disparar evento para processamento
            const event = new CustomEvent('telemetry', { detail: { deviceId, data } });
            window.dispatchEvent(event);
        } catch (error) {
            this.logger.error(`Erro ao processar telemetria: ${error}`);
        }
    }

    async sendCommand(deviceId: string, command: any): Promise<boolean> {
        const server = this.connectedDevices.get(deviceId);
        if (!server || !server.connected) {
            throw new Error(`Dispositivo ${deviceId} não está conectado`);
        }

        try {
            const service = await server.getPrimaryService(this.ESP32_SERVICE_UUID);
            const characteristic = await service.getCharacteristic(this.ESP32_CHAR_COMMAND_UUID);

            const encoder = new TextEncoder();
            const data = encoder.encode(JSON.stringify(command));

            await characteristic.writeValue(data);
            this.logger.info(`Comando enviado para ${deviceId}`);

            return true;
        } catch (error) {
            this.logger.error(`Erro ao enviar comando: ${error}`);
            return false;
        }
    }

    getDevices(): ESP32Device[] {
        return Array.from(this.devices.values());
    }

    getDevice(deviceId: string): ESP32Device | undefined {
        return this.devices.get(deviceId);
    }
}






