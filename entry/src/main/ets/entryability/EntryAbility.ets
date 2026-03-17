import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'MachineControl', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'MachineControl', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(0x0000, 'MachineControl', 'Ability onWindowStageCreate');

    // 设置沉浸式状态栏
    let windowClass = await windowStage.getMainWindow();
    await windowClass.setWindowLayoutFullScreen(true);

    const systemBarProperties: window.SystemBarProperties = {
      statusBarColor: '#0D1117',
      navigationBarColor: '#0D1117',
      statusBarContentColor: '#E6EDF3',
      navigationBarContentColor: '#E6EDF3'
    };
    await windowClass.setWindowSystemBarProperties(systemBarProperties);

    // 加载登录页面
    windowStage.loadContent('pages/LoginPage', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'MachineControl', 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, 'MachineControl', 'Succeeded in loading content');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'MachineControl', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'MachineControl', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'MachineControl', 'Ability onBackground');
  }
}
