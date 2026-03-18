import { router, promptAction } from '@kit.ArkUI';
import { DeviceDao } from 'datastore';
import { AuthManager, DeviceRefreshCoordinator } from 'utils';
import { AppColors, AppTypography, GradientButton, LoadingOverlay } from 'uikit';

/**
 * 管理员新增设备页面
 */
@Entry
@Component
struct CreateDevicePage {
  @State private deviceId: string = '';
  @State private address: string = '';
  @State private isSubmitting: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (!AuthManager.getInstance().canLockDevice()) {
      promptAction.showToast({ message: '仅管理员可新增设备', duration: 2000 });
      router.back();
    }
  }

  build() {
    Stack() {
      Column({ space: 16 }) {
        this.navBar()

        Column({ space: 20 }) {
          Column({ space: 8 }) {
            Text('新增设备')
              .fontSize(AppTypography.SIZE_HEADLINE)
              .fontWeight(AppTypography.WEIGHT_BOLD)
              .fontColor(AppColors.TEXT_PRIMARY)

            Text('仅录入设备编号和位置，系统会自动补齐初始状态、工作数和锁定信息。')
              .fontSize(AppTypography.SIZE_BODY)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          this.fieldBlock('设备编号', '例如 DEV006', this.deviceId, (value: string) => {
            this.deviceId = value;
            this.errorMessage = '';
          })

          this.textAreaBlock('设备位置', '请输入设备所在位置', this.address, (value: string) => {
            this.address = value;
            this.errorMessage = '';
          })

          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(AppTypography.SIZE_CAPTION)
              .fontColor(AppColors.DANGER)
              .width('100%')
          }

          GradientButton({
            text: this.isSubmitting ? '提交中' : '确认新增',
            gradientColors: AppColors.GRADIENT_PRIMARY,
            isDisabled: this.isSubmitting || !this.deviceId.trim() || !this.address.trim(),
            onButtonClick: () => this.submit()
          })

          Column({ space: 10 }) {
            this.tipRow('初始状态', '待机')
            this.tipRow('工作数量', '0')
            this.tipRow('锁定状态', '未锁定')
          }
          .width('100%')
          .padding(18)
          .backgroundColor(AppColors.BG_TERTIARY)
          .borderRadius(18)
        }
        .width('100%')
        .padding(20)
        .backgroundColor(AppColors.BG_SECONDARY)
        .borderRadius(24)
        .border({ width: 1, color: AppColors.BORDER })

        Blank()
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 20 })
      .backgroundColor(AppColors.BG_PRIMARY)

      LoadingOverlay({ isLoading: this.isSubmitting, message: '正在创建设备' })
    }
  }

  @Builder
  private navBar() {
    Row() {
      Text('返回')
        .fontSize(AppTypography.SIZE_BODY)
        .fontColor(AppColors.TEXT_PRIMARY)
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor(AppColors.BG_SECONDARY)
        .borderRadius(16)
        .border({ width: 1, color: AppColors.BORDER })
        .onClick(() => router.back())

      Blank()
    }
    .width('100%')
  }

  @Builder
  private fieldBlock(label: string, placeholder: string, value: string, onChange: (value: string) => void) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')

      TextInput({ placeholder: placeholder, text: value })
        .width('100%')
        .height(52)
        .padding({ left: 14, right: 14 })
        .backgroundColor(AppColors.BG_TERTIARY)
        .borderRadius(16)
        .border({ width: 1, color: AppColors.BORDER })
        .placeholderColor(AppColors.TEXT_TERTIARY)
        .fontColor(AppColors.TEXT_PRIMARY)
        .caretColor(AppColors.PRIMARY)
        .onChange(onChange)
    }
    .width('100%')
  }

  @Builder
  private textAreaBlock(label: string, placeholder: string, value: string, onChange: (value: string) => void) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')

      TextInput({ placeholder: placeholder, text: value })
        .width('100%')
        .height(120)
        .padding({ left: 14, right: 14, top: 14, bottom: 14 })
        .backgroundColor(AppColors.BG_TERTIARY)
        .borderRadius(16)
        .border({ width: 1, color: AppColors.BORDER })
        .placeholderColor(AppColors.TEXT_TERTIARY)
        .fontColor(AppColors.TEXT_PRIMARY)
        .caretColor(AppColors.PRIMARY)
        .maxLines(4)
        .onChange(onChange)
    }
    .width('100%')
  }

  @Builder
  private tipRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)

      Text(value)
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_PRIMARY)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  private async submit(): Promise<void> {
    const normalizedId = this.deviceId.trim().toUpperCase();
    const normalizedAddress = this.address.trim();

    if (!normalizedId || !normalizedAddress) {
      this.errorMessage = '请填写完整的设备编号和位置';
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';

    try {
      const device = await DeviceDao.getInstance().createDevice(normalizedId, normalizedAddress);
      DeviceRefreshCoordinator.getInstance().publishDeviceCreated(device.id);
      promptAction.showToast({ message: '设备新增成功', duration: 2000 });
      router.back();
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '新增设备失败，请稍后重试';
    } finally {
      this.isSubmitting = false;
    }
  }
}
