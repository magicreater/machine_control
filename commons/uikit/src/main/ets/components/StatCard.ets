import { AppColors } from '../theme/Colors';
import { AppTypography } from '../theme/Typography';

/**
 * 统计卡片组件
 */
@Component
export struct StatCard {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop icon: string = '';
  @Prop accentColor: string = AppColors.PRIMARY;

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.title)
          .fontSize(AppTypography.SIZE_CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)

        if (this.icon) {
          Text(this.icon)
            .fontSize(AppTypography.SIZE_SMALL)
            .fontColor(this.accentColor)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.accentColor + '12')
            .borderRadius(999)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Text(this.value)
        .fontSize(AppTypography.SIZE_HEADLINE)
        .fontWeight(AppTypography.WEIGHT_BOLD)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.BG_SECONDARY)
    .borderRadius(18)
    .border({
      width: 1,
      color: AppColors.BORDER
    })
    .shadow({
      radius: 10,
      color: AppColors.SHADOW_COLOR,
      offsetX: 0,
      offsetY: 4
    })
  }
}
