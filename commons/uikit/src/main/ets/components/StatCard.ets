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
    Column({ space: 8 }) {
      Row() {
        Text(this.icon)
          .fontSize(24)

        Text(this.title)
          .fontSize(AppTypography.SIZE_CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ left: 8 })
      }
      .width('100%')

      Text(this.value)
        .fontSize(AppTypography.SIZE_HEADLINE)
        .fontWeight(AppTypography.WEIGHT_BOLD)
        .fontColor(this.accentColor)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.BG_SECONDARY)
    .borderRadius(12)
    .border({
      width: 1,
      color: this.accentColor + '30'
    })
  }
}
