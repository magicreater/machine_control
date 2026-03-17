import { describe, it, expect } from '@ohos/hypium';
import { buildApiBaseUrl, mapDeviceDtoToModel, mapUserDtoToModel } from '../main/ets/ApiHelpers';
import { DeviceStatus, UserRole } from '../main/ets/models';

export default function apiClientTest() {
  describe('ApiHelpers', () => {
    it('buildApiBaseUrl returns host specific api path', 0, () => {
      const baseUrl = buildApiBaseUrl('10.252.131.134', 3000);
      expect(baseUrl).assertEqual('http://10.252.131.134:3000/api');
    });

    it('mapUserDtoToModel keeps role information', 0, () => {
      const user = mapUserDtoToModel({
        id: 'USR001',
        username: 'admin',
        role: 'admin'
      });

      expect(user.username).assertEqual('admin');
      expect(user.role).assertEqual(UserRole.ADMIN);
    });

    it('mapDeviceDtoToModel converts numeric and lock fields', 0, () => {
      const device = mapDeviceDtoToModel({
        id: 'DEV001',
        name: '数控机床-A01',
        address: 'test',
        latitude: 35.0827,
        longitude: 117.1536,
        status: 1,
        workCount: 1523,
        isLocked: true,
        lockedBy: 'admin',
        lockedAt: 1000,
        updatedAt: 2000
      });

      expect(device.status).assertEqual(DeviceStatus.WORKING);
      expect(device.isLocked).assertTrue();
      expect(device.lockedBy).assertEqual('admin');
    });
  });
}
