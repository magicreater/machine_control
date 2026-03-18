import { AppColors } from '../theme/Colors';
import { AppTypography } from '../theme/Typography';

/**
 * 加载遮罩组件
 */
@Component
export struct LoadingOverlay {
  @Prop isLoading: boolean = false;
  @Prop message: string = '加载中...';

  build() {
    if (this.isLoading) {
      Stack() {
        // 半透明背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(AppColors.OVERLAY_DARK)

        // 加载指示器
        Column({ space: 16 }) {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(AppColors.PRIMARY)

          Text(this.message)
            .fontSize(AppTypography.SIZE_BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .padding(24)
        .backgroundColor(AppColors.BG_SECONDARY)
        .borderRadius(20)
        .border({ width: 1, color: AppColors.BORDER })
        .shadow({
          radius: 20,
          color: AppColors.SHADOW_COLOR,
          offsetX: 0,
          offsetY: 8
        })
      }
      .width('100%')
      .height('100%')
    }
  }
}
