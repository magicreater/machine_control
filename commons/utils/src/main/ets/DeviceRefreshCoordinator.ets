export interface DeviceRefreshEvent {
  deviceId: string;
  kind: 'lock-status-changed' | 'device-created';
  version: number;
  changedAt: number;
}

type DeviceRefreshListener = (event: DeviceRefreshEvent) => void;

export class DeviceRefreshCoordinator {
  private static instance: DeviceRefreshCoordinator | null = null;
  private readonly listeners: Map<string, DeviceRefreshListener> = new Map();
  private version: number = 0;

  private constructor() { }

  static getInstance(): DeviceRefreshCoordinator {
    if (!DeviceRefreshCoordinator.instance) {
      DeviceRefreshCoordinator.instance = new DeviceRefreshCoordinator();
    }
    return DeviceRefreshCoordinator.instance;
  }

  publishLockStatusChanged(deviceId: string): DeviceRefreshEvent {
    return this.publish(deviceId, 'lock-status-changed');
  }

  publishDeviceCreated(deviceId: string): DeviceRefreshEvent {
    return this.publish(deviceId, 'device-created');
  }

  private publish(deviceId: string, kind: 'lock-status-changed' | 'device-created'): DeviceRefreshEvent {
    this.version += 1;
    const event: DeviceRefreshEvent = {
      deviceId: deviceId,
      kind: kind,
      version: this.version,
      changedAt: Date.now()
    };

    this.listeners.forEach((listener: DeviceRefreshListener) => {
      listener(event);
    });

    return event;
  }

  subscribe(key: string, listener: DeviceRefreshListener): void {
    this.listeners.set(key, listener);
  }

  unsubscribe(key: string): void {
    this.listeners.delete(key);
  }

  getVersion(): number {
    return this.version;
  }
}
