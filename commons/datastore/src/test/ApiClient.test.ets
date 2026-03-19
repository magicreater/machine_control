import { describe, it, expect } from '@ohos/hypium';
import { buildApiBaseUrl, mapDeviceDtoToModel, mapUserDtoToModel } from '../main/ets/ApiHelpers';
import { DeviceStatus, UserRole } from '../main/ets/models';
import { UserDao, UserApiClientBase } from '../main/ets/UserDao';

class MockCreateUserApiClient extends UserApiClientBase {
  requestedPath: string = '';
  payloadJson: string = '';

  post<T>(path: string, payload: Object): Promise<T> {
    this.requestedPath = path;
    this.payloadJson = JSON.stringify(payload);
    return Promise.resolve({
      id: 'USR003',
      username: 'quality_operator',
      role: 'user'
    } as T);
  }

  setAuthToken(_token: string): void {
  }

  clearAuthToken(): void {
  }
}

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
        badCount: 12,
        rottenCount: 4,
        greenSkinCount: 8,
        mechanicalDamageCount: 3,
        sproutedCount: 2,
        isLocked: true,
        lockedBy: 'admin',
        lockedAt: 1000,
        updatedAt: 2000
      });

      expect(device.status).assertEqual(DeviceStatus.WORKING);
      expect(device.badCount).assertEqual(12);
      expect(device.rottenCount).assertEqual(4);
      expect(device.greenSkinCount).assertEqual(8);
      expect(device.mechanicalDamageCount).assertEqual(3);
      expect(device.sproutedCount).assertEqual(2);
      expect(device.isLocked).assertTrue();
      expect(device.lockedBy).assertEqual('admin');
    });

    it('UserDao.createUser posts payload and maps response', 0, async () => {
      const apiClient = new MockCreateUserApiClient();
      const dao = UserDao.createForTesting(apiClient);

      const user = await dao.createUser('quality_operator', 'secret123', UserRole.USER);

      expect(apiClient.requestedPath).assertEqual('/users');
      expect(apiClient.payloadJson).assertContain('"username":"quality_operator"');
      expect(apiClient.payloadJson).assertContain('"password":"secret123"');
      expect(apiClient.payloadJson).assertContain('"role":"user"');
      expect(user.username).assertEqual('quality_operator');
      expect(user.role).assertEqual(UserRole.USER);
    });
  });
}
