import { router } from '@kit.ArkUI';

/**
 * 启动页 - 跳转到登录页
 */
@Entry
@Component
struct Index {
  aboutToAppear(): void {
    // 直接跳转到登录页
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  build() {
    Column() {
      // 空页面，立即跳转
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117')
  }
}
