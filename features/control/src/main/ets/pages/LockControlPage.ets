import { router, promptAction } from "@kit.ArkUI";
import { DeviceModel, DeviceDao } from "datastore";
import { AuthManager } from "utils";
import { AppColors, AppTypography, SlideToConfirm, LoadingOverlay, GradientButton } from "uikit";

interface RouteParams {
  deviceId: string;
}

/**
 * 锁定控制页面 - 含滑动确认和二次确认
 */
@Entry
@Component
export struct LockControlPage {
  @State private device: DeviceModel | null = null;
  @State private isLoading: boolean = true;
  @State private isProcessing: boolean = false;
  @State private deviceId: string = "";
  @State private slideConfirmed: boolean = false;
  @State private showConfirmDialog: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as RouteParams;
    if (params && params.deviceId) {
      this.deviceId = params.deviceId;
      this.loadDevice();
    }
  }

  private async loadDevice(): Promise<void> {
    try {
      this.device = await DeviceDao.getInstance().getDeviceById(this.deviceId);
    } catch (error) {
      console.error("Failed to load device:", error);
    } finally {
      this.isLoading = false;
    }
  }

  private async executeLockAction(): Promise<void> {
    if (!this.device) return;

    this.isProcessing = true;

    try {
      const newLockState = !this.device.isLocked;
      const username = AuthManager.getInstance().getCurrentUsername();

      const success = await DeviceDao.getInstance().updateLockStatus(
        this.device.id,
        newLockState,
        username,
      );

      if (success) {
        await this.loadDevice();

        promptAction.showToast({
          message: newLockState ? "设备已锁定" : "设备已解锁",
          duration: 2000,
        });

        // 延迟返回
        setTimeout(() => {
          router.back();
        }, 1500);
      } else {
        promptAction.showToast({
          message: "操作失败，请重试",
          duration: 2000,
        });
      }
    } catch (error) {
      console.error("Lock operation failed:", error);
      promptAction.showToast({
        message: "操作失败，请重试",
        duration: 2000,
      });
    } finally {
      this.isProcessing = false;
      this.showConfirmDialog = false;
      this.slideConfirmed = false;
    }
  }

  private handleSlideConfirm(): void {
    this.slideConfirmed = true;
    // 显示二次确认弹窗
    this.showConfirmDialog = true;
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航
        Row() {
          Row() {
            Text("←")
              .fontSize(24)
              .fontColor(AppColors.TEXT_PRIMARY)
          }
          .width(44)
          .height(44)
          .justifyContent(FlexAlign.Center)
          .borderRadius(22)
          .backgroundColor(AppColors.BG_TERTIARY)
          .onClick(() => router.back())
          Text(this.device?.isLocked ? "解除锁定" : "锁定设备")
            .fontSize(AppTypography.SIZE_TITLE)
            .fontWeight(AppTypography.WEIGHT_BOLD)
            .fontColor(AppColors.TEXT_PRIMARY)
            .margin({ left: 16 })
          Blank()
        }
        .width("100%")
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

        if (this.device) {
          Scroll() {
            Column({ space: 24 }) {
              // 警告提示
              this.warningSection()

              // 设备信息卡片
              this.deviceInfoCard()

              // 操作说明
              this.instructionSection()

              // 滑动确认区域
              this.slideConfirmSection()
            }
            .padding({ left: 16, right: 16, top: 16, bottom: 32 })
          }
          .layoutWeight(1)
          .scrollable(ScrollDirection.Vertical);
        }
      }
      .width("100%")
      .height("100%")
      .backgroundColor(AppColors.BG_PRIMARY)

      // 二次确认弹窗
      if (this.showConfirmDialog) {
        this.confirmDialog();
      }
      LoadingOverlay({
        isLoading: this.isLoading || this.isProcessing,
        message: this.isLoading ? "加载中..." : "处理中...",
      })
    };
  }

  @Builder
  private warningSection() {
    Row({ space: 12 }) {
      Text(this.device!.isLocked ? "⚠️" : "🔒").fontSize(32)
      Column({ space: 4 }) {
        Text(this.device!.isLocked ? "即将解除设备锁定" : "即将锁定此设备")
          .fontSize(AppTypography.SIZE_SUBTITLE)
          .fontWeight(AppTypography.WEIGHT_BOLD)
          .fontColor(this.device!.isLocked ? AppColors.WARNING : AppColors.DANGER)
        Text(
          this.device!.isLocked ? "解锁后设备可以正常开机运行" : "锁定后设备将无法开机，请谨慎操作",
        )
          .fontSize(AppTypography.SIZE_CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width("100%")
    .padding(16)
    .backgroundColor(this.device!.isLocked ? AppColors.WARNING + "15" : AppColors.DANGER + "15")
    .borderRadius(12)
    .border({
      width: 1,
      color: this.device!.isLocked ? AppColors.WARNING + "40" : AppColors.DANGER + "40",
    });
  }

  @Builder
  private deviceInfoCard() {
    Column({ space: 12 }) {
      Text("目标设备")
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_TERTIARY)
        .width("100%")
      Row() {
        Column({ space: 4 }) {
          Text(this.device!.name)
            .fontSize(AppTypography.SIZE_SUBTITLE)
            .fontWeight(AppTypography.WEIGHT_MEDIUM)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(this.device!.id)
            .fontSize(AppTypography.SIZE_SMALL)
            .fontColor(AppColors.TEXT_TERTIARY)
        }.alignItems(HorizontalAlign.Start)
        Text(this.device!.isLocked ? "🔒 已锁定" : "🟢 运行中")
          .fontSize(AppTypography.SIZE_CAPTION)
          .fontColor(this.device!.isLocked ? AppColors.DANGER : AppColors.SUCCESS)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(
            this.device!.isLocked ? AppColors.DANGER + "20" : AppColors.SUCCESS + "20",
          )
          .borderRadius(14)
      }
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)
      Divider().color(AppColors.BORDER)
      Row({ space: 8 }) {
        Text("📍").fontSize(16)
        Text(this.device!.address)
          .fontSize(AppTypography.SIZE_CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .layoutWeight(1)
      }
    }
    .width("100%")
    .padding(16)
    .backgroundColor(AppColors.BG_SECONDARY)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER });
  }

  @Builder
  private instructionSection() {
    Column({ space: 12 }) {
      Text("操作步骤")
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_TERTIARY)
        .width("100%")
      Column({ space: 8 }) {
        this.stepItem(1, "滑动下方滑块至最右侧", this.slideConfirmed)
        this.stepItem(2, "在弹出的对话框中点击确认", false)
      }
    }.width("100%");
  }

  @Builder
  private stepItem(step: number, text: string, completed: boolean) {
    Row({ space: 12 }) {
      Text(completed ? "✓" : step.toString())
        .fontSize(14)
        .fontColor(completed ? AppColors.SUCCESS : AppColors.TEXT_SECONDARY)
        .width(24)
        .height(24)
        .textAlign(TextAlign.Center)
        .backgroundColor(completed ? AppColors.SUCCESS + "20" : AppColors.BG_TERTIARY)
        .borderRadius(12)
      Text(text)
        .fontSize(AppTypography.SIZE_BODY)
        .fontColor(completed ? AppColors.TEXT_PRIMARY : AppColors.TEXT_SECONDARY)
    };
  }

  @Builder
  private slideConfirmSection() {
    Column({ space: 16 }) {
      if (!this.slideConfirmed) {
        SlideToConfirm({
          text: this.device!.isLocked ? "滑动解除锁定" : "滑动确认锁定",
          confirmText: "已确认",
          trackColor: this.device!.isLocked ? AppColors.SUCCESS : AppColors.DANGER,
          onConfirm: () => this.handleSlideConfirm(),
        });
      } else {
        Row() {
          Text("✓ 已滑动确认")
            .fontSize(AppTypography.SIZE_BODY)
            .fontColor(AppColors.SUCCESS)
        }
        .width("100%")
        .height(60)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.SUCCESS + "15")
        .borderRadius(30)
        .border({ width: 1, color: AppColors.SUCCESS + "40" });
      }
      Text("请仔细确认后再操作，避免误触")
        .fontSize(AppTypography.SIZE_SMALL)
        .fontColor(AppColors.TEXT_TERTIARY)
        .textAlign(TextAlign.Center)
        .width("100%")
    }
    .width("100%")
    .margin({ top: 16 });
  }

  @Builder
  private confirmDialog() {
    Stack() {
      // 半透明背景
      Column()
        .width("100%")
        .height("100%")
        .backgroundColor(AppColors.OVERLAY_DARK)
        .onClick(() => {
          this.showConfirmDialog = false;
          this.slideConfirmed = false;
        })

      // 对话框
      Column({ space: 20 }) {
        // 图标
        Text(this.device!.isLocked ? "🔓" : "🔒").fontSize(48)

        // 标题
        Text(this.device!.isLocked ? "确认解除锁定？" : "确认锁定设备？")
          .fontSize(AppTypography.SIZE_TITLE)
          .fontWeight(AppTypography.WEIGHT_BOLD)
          .fontColor(AppColors.TEXT_PRIMARY)

        // 说明
        Text(
          this.device!.isLocked
            ? `确定要解除「${this.device!.name}」的锁定状态吗？\n解锁后设备可以正常开机运行。`
            : `确定要锁定「${this.device!.name}」吗？\n锁定后设备将无法开机，直到解除锁定。`,
        )
          .fontSize(AppTypography.SIZE_BODY)
          .fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .lineHeight(24)

        // 操作者信息
        Row({ space: 8 }) {
          Text("👤").fontSize(16)
          Text(`操作者：${AuthManager.getInstance().getCurrentUsername()}`)
            .fontSize(AppTypography.SIZE_CAPTION)
            .fontColor(AppColors.TEXT_TERTIARY)
        }
        .padding({ top: 8, bottom: 8, left: 16, right: 16 })
        .backgroundColor(AppColors.BG_TERTIARY)
        .borderRadius(16)

        // 按钮组
        Row({ space: 12 }) {
          // 取消按钮
          Text("取消")
            .fontSize(AppTypography.SIZE_BODY)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width("45%")
            .height(48)
            .textAlign(TextAlign.Center)
            .backgroundColor(AppColors.BG_TERTIARY)
            .borderRadius(12)
            .onClick(() => {
              this.showConfirmDialog = false;
              this.slideConfirmed = false;
            })

          // 确认按钮
          GradientButton({
            text: "确认",
            gradientColors: this.device!.isLocked
              ? AppColors.GRADIENT_SUCCESS
              : AppColors.GRADIENT_DANGER,
            onButtonClick: () => this.executeLockAction(),
          }).width("45%")
        }
        .width("100%")
        .margin({ top: 8 })
      }
      .width("85%")
      .padding(24)
      .backgroundColor(AppColors.BG_SECONDARY)
      .borderRadius(20)
      .border({ width: 1, color: AppColors.BORDER })
      .shadow({
        radius: 24,
        color: AppColors.SHADOW_COLOR,
        offsetX: 0,
        offsetY: 12,
      })
    }
    .width("100%")
    .height("100%");
  }
}
