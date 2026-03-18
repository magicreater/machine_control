import { DeviceModel, DeviceStatus } from './models/DeviceModel';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiClient } from './ApiClient';
import { DeviceDto, mapDeviceDtoToModel } from './ApiHelpers';

const TAG = 'DeviceDao';
const DOMAIN = 0x0000;

interface LockStatusPayload {
    isLocked: boolean;
    operator: string;
}

interface CreateDevicePayload {
    id: string;
    address: string;
}

/**
 * 设备数据访问对象
 */
export class DeviceDao {
    private static instance: DeviceDao | null = null;

    private constructor() { }

    static getInstance(): DeviceDao {
        if (!DeviceDao.instance) {
            DeviceDao.instance = new DeviceDao();
        }
        return DeviceDao.instance;
    }

    /**
     * 获取所有设备
     */
    async getAllDevices(): Promise<DeviceModel[]> {
        try {
            const response = await ApiClient.getInstance().get<DeviceDto[]>('/devices');
            return response.map((item: DeviceDto) => mapDeviceDtoToModel(item));
        } catch (error) {
            hilog.error(DOMAIN, TAG, `getAllDevices failed: ${error}`);
            if (error instanceof Error) {
                throw new Error(error.message);
            }
            throw new Error('加载设备失败，请检查后端服务');
        }
    }

    /**
     * 根据ID获取设备
     */
    async getDeviceById(id: string): Promise<DeviceModel | null> {
        try {
            const response = await ApiClient.getInstance().get<DeviceDto>(`/devices/${id}`);
            return mapDeviceDtoToModel(response);
        } catch (error) {
            hilog.error(DOMAIN, TAG, `getDeviceById failed: ${error}`);
            if (error instanceof Error && error.message === '设备不存在') {
                return null;
            }
            if (error instanceof Error) {
                throw new Error(error.message);
            }
            throw new Error('加载设备详情失败，请检查后端服务');
        }
    }

    /**
     * 更新设备锁定状态
     */
    async updateLockStatus(deviceId: string, isLocked: boolean, lockedBy: string): Promise<boolean> {
        const payload: LockStatusPayload = {
            isLocked: isLocked,
            operator: lockedBy
        };
        try {
            await ApiClient.getInstance().put<DeviceDto>(`/devices/${deviceId}/lock`, payload);
            return true;
        } catch (error) {
            hilog.error(DOMAIN, TAG, `updateLockStatus failed: ${error}`);
            return false;
        }
    }

    /**
     * 更新设备状态
     */
    async updateDeviceStatus(deviceId: string, status: DeviceStatus): Promise<boolean> {
        hilog.warn(DOMAIN, TAG, `updateDeviceStatus is not supported by the HTTP API. deviceId=${deviceId}, status=${status}`);
        return false;
    }

    /**
     * 更新工作数量
     */
    async updateWorkCount(deviceId: string, workCount: number): Promise<boolean> {
        hilog.warn(DOMAIN, TAG, `updateWorkCount is not supported by the HTTP API. deviceId=${deviceId}, workCount=${workCount}`);
        return false;
    }

    /**
     * 新建设备
     */
    async createDevice(id: string, address: string): Promise<DeviceModel> {
        const payload: CreateDevicePayload = {
            id: id.trim(),
            address: address.trim()
        };
        try {
            const response = await ApiClient.getInstance().post<DeviceDto>('/devices', payload);
            return mapDeviceDtoToModel(response);
        } catch (error) {
            hilog.error(DOMAIN, TAG, `createDevice failed: ${error}`);
            if (error instanceof Error) {
                throw new Error(error.message);
            }
            throw new Error('新增设备失败，请稍后重试');
        }
    }

    /**
     * 获取已锁定的设备
     */
    async getLockedDevices(): Promise<DeviceModel[]> {
        const devices = await this.getAllDevices();
        return devices.filter((device: DeviceModel) => device.isLocked);
    }

    /**
     * 获取工作中的设备
     */
    async getWorkingDevices(): Promise<DeviceModel[]> {
        const devices = await this.getAllDevices();
        return devices.filter((device: DeviceModel) => device.status === DeviceStatus.WORKING && !device.isLocked);
    }
}
