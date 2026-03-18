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
    Column({ space: 14 }) {
      Row() {
        Row({ space: 10 }) {
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
            Text('已锁定')
              .fontSize(AppTypography.SIZE_SMALL)
              .fontColor(AppColors.DANGER)
          }
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(AppColors.DANGER + '12')
          .borderRadius(999)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
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
      .padding({ top: 2 })

      Row() {
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
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppColors.BG_SECONDARY)
    .borderRadius(20)
    .border({ width: 1, color: AppColors.BORDER })
    .shadow({
      radius: 18,
      color: AppColors.SHADOW_COLOR,
      offsetX: 0,
      offsetY: 6
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
