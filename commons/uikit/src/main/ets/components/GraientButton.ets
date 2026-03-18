import { AppColors } from "../theme/Colors";
import { AppTypography } from "../theme/Typography";

/**
 * 渐变按钮组件
 */
@Component
export struct GradientButton {
  @Prop text: string = "";
  @Prop icon: string = "";
  @Prop gradientColors: [string, string] = AppColors.GRADIENT_PRIMARY;
  @Prop isDisabled: boolean = false;
  @State private isPressed: boolean = false;
  onButtonClick?: () => void;

  build() {
    Row({ space: 8 }) {
      if (this.icon) {
        Text(this.icon).fontSize(20);
      }
      Text(this.text)
        .fontSize(AppTypography.SIZE_BODY)
        .fontWeight(AppTypography.WEIGHT_MEDIUM)
        .fontColor(AppColors.TEXT_ON_PRIMARY)
    }
    .width("100%")
    .height(52)
    .justifyContent(FlexAlign.Center)
    .borderRadius(16)
    .linearGradient({
      angle: 90,
      colors: this.isDisabled
        ? [
          [AppColors.BG_ELEVATED, 0],
          [AppColors.BG_TERTIARY, 1],
        ]
        : [
          [this.gradientColors[0], 0],
          [this.gradientColors[1], 1],
        ],
    })
    .opacity(this.isPressed ? 0.8 : 1)
    .scale({ x: this.isPressed ? 0.98 : 1, y: this.isPressed ? 0.98 : 1 })
    .shadow({
      radius: this.isPressed ? 4 : 12,
      color: this.isDisabled ? "transparent" : this.gradientColors[0] + "40",
      offsetX: 0,
      offsetY: this.isPressed ? 2 : 6,
    })
    .animation({
      duration: 150,
      curve: Curve.EaseOut,
    })
    .onTouch((event) => {
      if (this.isDisabled) return;

      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onClick(() => {
      if (!this.isDisabled && this.onButtonClick) {
        this.onButtonClick();
      }
    });
  }
}
