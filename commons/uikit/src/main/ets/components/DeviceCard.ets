import { AppColors } from '../theme/Colors';
import { AppTypography } from '../theme/Typography';
import { StatusIndicator } from './StatusIndicator';

/**
 * 设备卡片组件
 */
@Component
export struct DeviceCard {
  @Prop deviceId: string = '';
  @Prop deviceName: string = '';
  @Prop address: string = '';
  @Prop status: number = 0;
  @Prop workCount: number = 0;
  @Prop isLocked: boolean = false;
  onCardClick?: () => void;

  build() {
    Column() {
      // 顶部：设备名称和状态
      Row() {
        Row({ space: 8 }) {
          StatusIndicator({ status: this.status, isLocked: this.isLocked, indicatorSize: 12 })

          Column() {
            Text(this.deviceName)
              .fontSize(AppTypography.SIZE_SUBTITLE)
              .fontWeight(AppTypography.WEIGHT_MEDIUM)
              .fontColor(AppColors.TEXT_PRIMARY)

            Text(this.deviceId)
              .fontSize(AppTypography.SIZE_SMALL)
              .fontColor(AppColors.TEXT_TERTIARY)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
        }

        // 锁定标识
        if (this.isLocked) {
          Row() {
            Text('🔒')
              .fontSize(14)
            Text('已锁定')
              .fontSize(AppTypography.SIZE_SMALL)
              .fontColor(AppColors.DANGER)
              .margin({ left: 4 })
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(AppColors.OVERLAY_LIGHT)
          .borderRadius(12)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // 分隔线
      Divider()
        .color(AppColors.BORDER)
        .margin({ top: 12, bottom: 12 })

      // 地址信息
      Row() {
        Text('📍')
          .fontSize(14)
        Text(this.address)
          .fontSize(AppTypography.SIZE_CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 6 })
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 底部统计
      Row() {
        // 工作数量
        Column() {
          Text('工作数量')
            .fontSize(AppTypography.SIZE_SMALL)
            .fontColor(AppColors.TEXT_TERTIARY)

          Text(this.formatNumber(this.workCount))
            .fontSize(AppTypography.SIZE_TITLE)
            .fontWeight(AppTypography.WEIGHT_BOLD)
            .fontColor(AppColors.PRIMARY)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        // 状态文字
        Text(this.getStatusText())
          .fontSize(AppTypography.SIZE_BODY)
          .fontColor(this.getStatusColor())
          .fontWeight(AppTypography.WEIGHT_MEDIUM)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.getStatusColor() + '20')
          .borderRadius(16)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Bottom)
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.BG_SECONDARY)
    .borderRadius(16)
    .border({ width: 1, color: AppColors.BORDER })
    .shadow({
      radius: 16,
      color: AppColors.SHADOW_COLOR,
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick();
      }
    })
    .animation({
      duration: 200,
      curve: Curve.EaseOut
    })
  }

  private getStatusText(): string {
    if (this.isLocked) return '已锁定';
    switch (this.status) {
      case 1: return '工作中';
      case 2: return '待机';
      default: return '离线';
    }
  }

  private getStatusColor(): string {
    if (this.isLocked) return AppColors.DANGER;
    switch (this.status) {
      case 1: return AppColors.SUCCESS;
      case 2: return AppColors.WARNING;
      default: return AppColors.TEXT_TERTIARY;
    }
  }

  private formatNumber(num: number): string {
    if (num >= 10000) {
      return (num / 10000).toFixed(1) + '万';
    }
    return num.toLocaleString();
  }
}
