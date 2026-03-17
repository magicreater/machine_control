export interface DeviceRefreshEvent {
  deviceId: string;
  kind: 'lock-status-changed';
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
    this.version += 1;
    const event: DeviceRefreshEvent = {
      deviceId: deviceId,
      kind: 'lock-status-changed',
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
