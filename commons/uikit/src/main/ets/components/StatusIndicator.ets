import { AppColors } from "../theme/Colors";

/**
 * 设备状态指示器组件 - 带呼吸灯动画效果
 */
@Preview
@Component
export struct StatusIndicator {
  @Prop status: number = 0; // 0:离线 1:工作中 2:待机
  @Prop isLocked: boolean = false;
  @Prop indicatorSize: number = 12;
  @State private indicatorOpacity: number = 1;

  build() {
    Stack() {
      // 外圈光晕效果
      Circle()
        .width(this.indicatorSize + 8)
        .height(this.indicatorSize + 8)
        .fill(this.getStatusColor())
        .opacity(this.status === 1 && !this.isLocked ? this.indicatorOpacity * 0.3 : 0.2)

      // 内圈实心点
      Circle()
        .width(this.indicatorSize)
        .height(this.indicatorSize)
        .fill(this.getStatusColor())
        .shadow({
          radius: 8,
          color: this.getStatusColor(),
          offsetX: 0,
          offsetY: 0,
        })
    }
    .onAppear(() => {
      if (this.status === 1 && !this.isLocked) {
        this.startBreathingAnimation();
      }
    });
  }

  private getStatusColor(): string {
    if (this.isLocked) return AppColors.DANGER;
    switch (this.status) {
      case 1:
        return AppColors.SUCCESS;
      case 2:
        return AppColors.WARNING;
      default:
        return AppColors.TEXT_TERTIARY;
    }
  }

  private startBreathingAnimation(): void {
    animateTo(
      {
        duration: 1500,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate,
      },
      () => {
        this.indicatorOpacity = 0.4;
      },
    );
  }
}
