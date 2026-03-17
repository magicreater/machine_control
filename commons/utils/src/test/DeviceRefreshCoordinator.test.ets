import { describe, it, expect } from '@ohos/hypium';
import { DeviceRefreshCoordinator } from '../main/ets/DeviceRefreshCoordinator';

export default function deviceRefreshCoordinatorTest() {
  describe('DeviceRefreshCoordinator', () => {
    it('publishLockStatusChanged increments version and returns event payload', 0, () => {
      const coordinator = DeviceRefreshCoordinator.getInstance();
      const beforeVersion = coordinator.getVersion();

      const event = coordinator.publishLockStatusChanged('DEV001');

      expect(event.deviceId).assertEqual('DEV001');
      expect(event.kind).assertEqual('lock-status-changed');
      expect(event.version).assertEqual(beforeVersion + 1);
      expect(coordinator.getVersion()).assertEqual(beforeVersion + 1);
      expect(event.changedAt > 0).assertTrue();
    });

    it('subscribe receives published events and unsubscribe stops delivery', 0, () => {
      const coordinator = DeviceRefreshCoordinator.getInstance();
      const listenerKey = 'test-listener';
      let receivedCount = 0;
      let receivedDeviceId = '';

      coordinator.subscribe(listenerKey, (event) => {
        receivedCount++;
        receivedDeviceId = event.deviceId;
      });

      coordinator.publishLockStatusChanged('DEV002');

      expect(receivedCount).assertEqual(1);
      expect(receivedDeviceId).assertEqual('DEV002');

      coordinator.unsubscribe(listenerKey);
      coordinator.publishLockStatusChanged('DEV003');

      expect(receivedCount).assertEqual(1);
    });
  });
}
