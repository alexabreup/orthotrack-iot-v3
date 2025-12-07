export interface ESP32Device {
    id: string;
    name: string;
    address: string;
    rssi?: number;
    connected: boolean;
    lastSeen?: Date;
    batteryLevel?: number;
    firmwareVersion?: string;
    services?: string[];
    characteristics?: string[];
}

export interface TelemetryData {
    device_id: string;
    timestamp: string;
    sensors: {
        [key: string]: {
            type: string;
            value: any;
            unit?: string;
        };
    };
    battery_level?: number;
    status?: string;
}

export interface DeviceCommand {
    command_id: number;
    command_type: string;
    parameters: any;
    timestamp: string;
}






