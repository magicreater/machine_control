import { relationalStore } from '@kit.ArkData';
import { DeviceModel, DeviceModelOptions, DeviceStatus } from './models/DeviceModel';
import { Database } from './Database';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'DeviceDao';
const DOMAIN = 0x0000;

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

    private getStore(): relationalStore.RdbStore {
        return Database.getInstance().getStore();
    }

    /**
     * 获取所有设备
     */
    async getAllDevices(): Promise<DeviceModel[]> {
        const devices: DeviceModel[] = [];
        try {
            const predicates = new relationalStore.RdbPredicates('devices');
            const result = await this.getStore().query(predicates);

            try {
                while (result.goToNextRow()) {
                    devices.push(this.resultToDevice(result));
                }
            } finally {
                result.close();
            }
        } catch (error) {
            hilog.error(DOMAIN, TAG, `getAllDevices failed: ${error}`);
        }
        return devices;
    }

    /**
     * 根据ID获取设备
     */
    async getDeviceById(id: string): Promise<DeviceModel | null> {
        let device: DeviceModel | null = null;
        try {
            const predicates = new relationalStore.RdbPredicates('devices');
            predicates.equalTo('id', id);
            const result = await this.getStore().query(predicates);

            try {
                if (result.goToNextRow()) {
                    device = this.resultToDevice(result);
                }
            } finally {
                result.close();
            }
        } catch (error) {
            hilog.error(DOMAIN, TAG, `getDeviceById failed: ${error}`);
        }
        return device;
    }

    /**
     * 更新设备锁定状态
     */
    async updateLockStatus(deviceId: string, isLocked: boolean, lockedBy: string): Promise<boolean> {
        try {
            const predicates = new relationalStore.RdbPredicates('devices');
            predicates.equalTo('id', deviceId);

            const values: relationalStore.ValuesBucket = {
                is_locked: isLocked ? 1 : 0,
                locked_by: isLocked ? lockedBy : '',
                locked_at: isLocked ? Date.now() : 0,
                updated_at: Date.now()
            };

            const rows = await this.getStore().update(values, predicates);
            return rows > 0;
        } catch (error) {
            hilog.error(DOMAIN, TAG, `updateLockStatus failed: ${error}`);
            return false;
        }
    }

    /**
     * 更新设备状态
     */
    async updateDeviceStatus(deviceId: string, status: DeviceStatus): Promise<boolean> {
        try {
            const predicates = new relationalStore.RdbPredicates('devices');
            predicates.equalTo('id', deviceId);

            const values: relationalStore.ValuesBucket = {
                status: status,
                updated_at: Date.now()
            };

            const rows = await this.getStore().update(values, predicates);
            return rows > 0;
        } catch (error) {
            hilog.error(DOMAIN, TAG, `updateDeviceStatus failed: ${error}`);
            return false;
        }
    }

    /**
     * 更新工作数量
     */
    async updateWorkCount(deviceId: string, workCount: number): Promise<boolean> {
        try {
            const predicates = new relationalStore.RdbPredicates('devices');
            predicates.equalTo('id', deviceId);

            const values: relationalStore.ValuesBucket = {
                work_count: workCount,
                updated_at: Date.now()
            };

            const rows = await this.getStore().update(values, predicates);
            return rows > 0;
        } catch (error) {
            hilog.error(DOMAIN, TAG, `updateWorkCount failed: ${error}`);
            return false;
        }
    }

    /**
     * 获取已锁定的设备
     */
    async getLockedDevices(): Promise<DeviceModel[]> {
        const devices: DeviceModel[] = [];
        try {
            const predicates = new relationalStore.RdbPredicates('devices');
            predicates.equalTo('is_locked', 1);
            const result = await this.getStore().query(predicates);

            try {
                while (result.goToNextRow()) {
                    devices.push(this.resultToDevice(result));
                }
            } finally {
                result.close();
            }
        } catch (error) {
            hilog.error(DOMAIN, TAG, `getLockedDevices failed: ${error}`);
        }
        return devices;
    }

    /**
     * 获取工作中的设备
     */
    async getWorkingDevices(): Promise<DeviceModel[]> {
        const devices: DeviceModel[] = [];
        try {
            const predicates = new relationalStore.RdbPredicates('devices');
            predicates.equalTo('status', DeviceStatus.WORKING);
            predicates.equalTo('is_locked', 0);
            const result = await this.getStore().query(predicates);

            try {
                while (result.goToNextRow()) {
                    devices.push(this.resultToDevice(result));
                }
            } finally {
                result.close();
            }
        } catch (error) {
            hilog.error(DOMAIN, TAG, `getWorkingDevices failed: ${error}`);
        }
        return devices;
    }

    /**
     * 将查询结果转换为设备模型
     */
    private resultToDevice(result: relationalStore.ResultSet): DeviceModel {
        const options: DeviceModelOptions = {
            id: result.getString(result.getColumnIndex('id')),
            name: result.getString(result.getColumnIndex('name')),
            address: result.getString(result.getColumnIndex('address')),
            latitude: result.getDouble(result.getColumnIndex('latitude')),
            longitude: result.getDouble(result.getColumnIndex('longitude')),
            status: result.getLong(result.getColumnIndex('status')) as DeviceStatus,
            workCount: result.getLong(result.getColumnIndex('work_count')),
            isLocked: result.getLong(result.getColumnIndex('is_locked')) === 1,
            lockedBy: result.getString(result.getColumnIndex('locked_by')),
            lockedAt: result.getLong(result.getColumnIndex('locked_at')),
            updatedAt: result.getLong(result.getColumnIndex('updated_at'))
        };
        return new DeviceModel(options);
    }
}
