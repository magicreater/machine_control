import { router, promptAction } from '@kit.ArkUI';
import { DeviceModel, DeviceDao, DeviceStatus } from 'datastore';
import { AuthManager, TimerManager, Constants } from 'utils';
import { AppColors, AppTypography, StatusIndicator, GradientButton, LoadingOverlay } from 'uikit';

interface RouteParams {
  deviceId: string;
}

/**
 * 设备详情页面
 */
@Entry
@Component
struct DeviceDetailPage {
  @State private device: DeviceModel | null = null;
  @State private isLoading: boolean = true;
  @State private deviceId: string = '';
  @State private hasShownLoadError: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as RouteParams;
    if (params?.deviceId) {
      this.deviceId = params.deviceId;
      this.loadDevice();
      this.startAutoRefresh();
    }
  }

  aboutToDisappear(): void {
    TimerManager.getInstance().stopTimer('detail_refresh');
  }

  private async loadDevice(): Promise<void> {
    try {
      this.device = await DeviceDao.getInstance().getDeviceById(this.deviceId);
      if (this.device) {
        this.hasShownLoadError = false;
      } else if (!this.hasShownLoadError) {
        promptAction.showToast({ message: '设备不存在或已被删除', duration: 2000 });
        this.hasShownLoadError = true;
      }
    } catch (error) {
      console.error('Failed to load device:', error);
      if (!this.hasShownLoadError) {
        promptAction.showToast({ message: '加载设备详情失败，请检查后端服务', duration: 2000 });
        this.hasShownLoadError = true;
      }
    } finally {
      this.isLoading = false;
    }
  }

  private startAutoRefresh(): void {
    TimerManager.getInstance().startTimer('detail_refresh', () => this.loadDevice(), Constants.REFRESH_INTERVAL, false);
  }

  private navigateToLockControl(): void {
    if (!this.device) return;
    router.pushUrl({ url: 'pages/LockControlPage', params: { deviceId: this.device.id } });
  }

  private formatDate(ts: number): string {
    if (!ts) return '-';
    const d = new Date(ts);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }

  build() {
    Stack() {
      Column() {
        // 导航栏
        Row() {
          Row() {
            Text('←')
              .fontSize(24)
              .fontColor(AppColors.TEXT_PRIMARY)
          }
          .width(44)
          .height(44)
          .justifyContent(FlexAlign.Center)
          .borderRadius(22)
          .backgroundColor(AppColors.BG_TERTIARY)
          .onClick(() => router.back())

          Text('设备详情')
            .fontSize(AppTypography.SIZE_TITLE)
            .fontWeight(AppTypography.WEIGHT_BOLD)
            .fontColor(AppColors.TEXT_PRIMARY)
            .margin({ left: 16 })

          Blank()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

        if (this.device) {
          Scroll() {
            Column({ space: 16 }) {
              // 状态卡片
              Column({ space: 16 }) {
                Row() {
                  Column({ space: 8 }) {
                    Text(this.device.name)
                      .fontSize(AppTypography.SIZE_HEADLINE)
                      .fontWeight(AppTypography.WEIGHT_BOLD)
                      .fontColor(AppColors.TEXT_PRIMARY)
                    Text(this.device.id)
                      .fontSize(AppTypography.SIZE_CAPTION)
                      .fontColor(AppColors.TEXT_TERTIARY)
                  }
                  .alignItems(HorizontalAlign.Start)

                  StatusIndicator({ status: this.device.status, isLocked: this.device.isLocked, indicatorSize: 24 })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)

                Row() {
                  Text(this.device.getStatusText())
                    .fontSize(AppTypography.SIZE_BODY)
                    .fontWeight(AppTypography.WEIGHT_MEDIUM)
                    .fontColor(AppColors.TEXT_ON_PRIMARY)
                    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                    .borderRadius(20)
                    .linearGradient({
                      angle: 90,
                      colors: this.getGradient()
                    })
                }
                .width('100%')
              }
              .width('100%')
              .padding(20)
              .backgroundColor(AppColors.BG_SECONDARY)
              .borderRadius(16)
              .border({ width: 1, color: AppColors.BORDER })

              // 基本信息
              Column({ space: 16 }) {
                Text('基本信息')
                  .fontSize(AppTypography.SIZE_SUBTITLE)
                  .fontWeight(AppTypography.WEIGHT_MEDIUM)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .width('100%')

                this.infoRow('📍', '位置', this.device.address)
                Divider().color(AppColors.BORDER)
                this.infoRow('🌐', '经纬度', `${this.device.latitude.toFixed(4)}, ${this.device.longitude.toFixed(4)}`)
                Divider().color(AppColors.BORDER)
                this.infoRow('🕐', '更新时间', this.formatDate(this.device.updatedAt))

                if (this.device.isLocked) {
                  Divider().color(AppColors.BORDER)
                  this.infoRow('🔒', '锁定者', this.device.lockedBy)
                  Divider().color(AppColors.BORDER)
                  this.infoRow('⏰', '锁定时间', this.formatDate(this.device.lockedAt))
                }
              }
              .width('100%')
              .padding(20)
              .backgroundColor(AppColors.BG_SECONDARY)
              .borderRadius(16)
              .border({ width: 1, color: AppColors.BORDER })

              // 工作统计
              Column({ space: 16 }) {
                Text('工作统计')
                  .fontSize(AppTypography.SIZE_SUBTITLE)
                  .fontWeight(AppTypography.WEIGHT_MEDIUM)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .width('100%')

                Column() {
                  Text('总工作数量')
                    .fontSize(AppTypography.SIZE_CAPTION)
                    .fontColor(AppColors.TEXT_TERTIARY)
                  Text(this.device.workCount.toLocaleString())
                    .fontSize(AppTypography.SIZE_DISPLAY)
                    .fontWeight(AppTypography.WEIGHT_BOLD)
                    .fontColor(AppColors.PRIMARY)
                    .margin({ top: 8 })
                }
                .width('100%')
                .padding({ top: 16, bottom: 16 })
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .padding(20)
              .backgroundColor(AppColors.BG_SECONDARY)
              .borderRadius(16)
              .border({ width: 1, color: AppColors.BORDER })

              // 操作按钮
              if (AuthManager.getInstance().canLockDevice()) {
                Column() {
                  if (this.device.isLocked) {
                    GradientButton({ text: '解除锁定', icon: '🔓', gradientColors: AppColors.GRADIENT_SUCCESS, onButtonClick: () => this.navigateToLockControl() })
                  } else {
                    GradientButton({ text: '锁定设备', icon: '🔒', gradientColors: AppColors.GRADIENT_DANGER, onButtonClick: () => this.navigateToLockControl() })
                  }
                }
                .width('100%')
                .padding({ top: 16 })
              }
            }
            .padding({ left: 16, right: 16, bottom: 32 })
          }
          .layoutWeight(1)
          .scrollable(ScrollDirection.Vertical)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG_PRIMARY)

      LoadingOverlay({ isLoading: this.isLoading, message: '加载中...' })
    }
  }

  @Builder
  private infoRow(icon: string, label: string, value: string) {
    Row() {
      Row({ space: 8 }) {
        Text(icon).fontSize(18)
        Text(label).fontSize(AppTypography.SIZE_BODY).fontColor(AppColors.TEXT_SECONDARY)
      }
      Text(value)
        .fontSize(AppTypography.SIZE_BODY)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .maxLines(2)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  private getGradient(): [string, number][] {
    if (this.device!.isLocked) return [[AppColors.DANGER, 0], [AppColors.DANGER + 'CC', 1]];
    switch (this.device!.status) {
      case DeviceStatus.WORKING: return [[AppColors.SUCCESS, 0], [AppColors.SUCCESS + 'CC', 1]];
      case DeviceStatus.STANDBY: return [[AppColors.WARNING, 0], [AppColors.WARNING + 'CC', 1]];
      default: return [[AppColors.TEXT_TERTIARY, 0], [AppColors.TEXT_TERTIARY + 'CC', 1]];
    }
  }
}
