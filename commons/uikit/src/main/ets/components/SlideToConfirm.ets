import { AppColors } from '../theme/Colors';
import { AppTypography } from '../theme/Typography';

/**
 * 滑动确认组件
 */
@Component
export struct SlideToConfirm {
  @Prop text: string = '滑动确认';
  @Prop confirmText: string = '已确认';
  @Prop trackColor: string = AppColors.DANGER;
  @State private offsetX: number = 0;
  @State private isConfirmed: boolean = false;
  @State private trackWidth: number = 0;
  private readonly thumbSize: number = 56;
  private readonly threshold: number = 0.8;
  onConfirm?: () => void;

  build() {
    Column() {
      Stack({ alignContent: Alignment.Start }) {
        // 背景轨道
        Row()
          .width('100%')
          .height(60)
          .backgroundColor(AppColors.BG_TERTIARY)
          .borderRadius(30)
          .border({ width: 1, color: AppColors.BORDER })
          .onAreaChange((oldArea, newArea) => {
            this.trackWidth = newArea.width as number;
          })

        // 进度填充
        Row()
          .width(this.offsetX + this.thumbSize)
          .height(60)
          .borderRadius(30)
          .linearGradient({
            angle: 90,
            colors: [[this.trackColor, 0], [this.trackColor + 'CC', 1]]
          })

        // 提示文字
        Row() {
          Text(this.isConfirmed ? this.confirmText : this.text)
            .fontSize(AppTypography.SIZE_BODY)
            .fontColor(this.isConfirmed ? AppColors.TEXT_ON_PRIMARY : AppColors.TEXT_SECONDARY)
            .fontWeight(AppTypography.WEIGHT_MEDIUM)
        }
        .width('100%')
        .height(60)
        .justifyContent(FlexAlign.Center)

        // 滑动按钮
        Row() {
          Text(this.isConfirmed ? '✓' : '→')
            .fontSize(24)
            .fontColor(AppColors.TEXT_ON_PRIMARY)
        }
        .width(this.thumbSize)
        .height(this.thumbSize)
        .margin({ left: 2 })
        .justifyContent(FlexAlign.Center)
        .borderRadius(this.thumbSize / 2)
        .linearGradient({
          angle: 135,
          colors: [
            [this.isConfirmed ? AppColors.SUCCESS : this.trackColor, 0],
            [this.isConfirmed ? AppColors.SUCCESS_LIGHT : this.trackColor + 'CC', 1]
          ]
        })
        .shadow({
          radius: 8,
          color: AppColors.SHADOW_COLOR,
          offsetX: 2,
          offsetY: 2
        })
        .translate({ x: this.offsetX })
        .gesture(
          PanGesture({ direction: PanDirection.Horizontal })
            .onActionUpdate((event: GestureEvent) => {
              if (this.isConfirmed) return;

              const maxOffset = this.trackWidth - this.thumbSize - 4;
              let newOffset = event.offsetX;

              if (newOffset < 0) newOffset = 0;
              if (newOffset > maxOffset) newOffset = maxOffset;

              this.offsetX = newOffset;
            })
            .onActionEnd(() => {
              if (this.isConfirmed) return;

              const maxOffset = this.trackWidth - this.thumbSize - 4;
              const progress = this.offsetX / maxOffset;

              if (progress >= this.threshold) {
                // 确认成功
                animateTo({
                  duration: 200,
                  curve: Curve.EaseOut
                }, () => {
                  this.offsetX = maxOffset;
                  this.isConfirmed = true;
                });

                if (this.onConfirm) {
                  this.onConfirm();
                }
              } else {
                // 回弹
                animateTo({
                  duration: 300,
                  curve: Curve.EaseOut
                }, () => {
                  this.offsetX = 0;
                });
              }
            })
        )
      }
      .width('100%')
    }
  }

  /**
   * 重置滑动状态
   */
  reset(): void {
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.offsetX = 0;
      this.isConfirmed = false;
    });
  }
}
