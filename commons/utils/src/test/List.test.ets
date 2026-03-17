import localUnitTest from './LocalUnit.test';
import deviceRefreshCoordinatorTest from './DeviceRefreshCoordinator.test';

export default function testsuite() {
  localUnitTest();
  deviceRefreshCoordinatorTest();
}
