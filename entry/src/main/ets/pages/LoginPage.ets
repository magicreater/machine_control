import { router } from '@kit.ArkUI';
import { UserDao } from 'datastore';
import { AuthManager } from 'utils';
import { AppColors, AppTypography, GradientButton, LoadingOverlay } from 'uikit';

/**
 * 登录页面
 */
@Entry
@Component
struct LoginPage {
  @State private username: string = '';
  @State private password: string = '';
  @State private isLoading: boolean = false;
  @State private errorMessage: string = '';
  @State private showPassword: boolean = false;

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.BG_PRIMARY)

      Column() {
        Scroll() {
          Column({ space: 24 }) {
            Column({ space: 14 }) {
              Text('Machine Control')
                .fontSize(AppTypography.SIZE_DISPLAY)
                .fontWeight(AppTypography.WEIGHT_BOLD)
                .fontColor(AppColors.TEXT_PRIMARY)

              Text('管理员可执行设备新增与锁定操作，普通用户仅查看设备状态。')
                .fontSize(AppTypography.SIZE_BODY)
                .fontColor(AppColors.TEXT_SECONDARY)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .margin({ top: 56, bottom: 24 })

            Column({ space: 18 }) {
              this.inputBlock('用户名', '请输入用户名', this.username, false, (value: string) => {
                this.username = value;
                this.errorMessage = '';
              })

              this.inputBlock('密码', '请输入密码', this.password, true, (value: string) => {
                this.password = value;
                this.errorMessage = '';
              })

              if (this.errorMessage) {
                Text(this.errorMessage)
                  .fontSize(AppTypography.SIZE_CAPTION)
                  .fontColor(AppColors.DANGER)
                  .width('100%')
              }

              GradientButton({
                text: '登录',
                gradientColors: AppColors.GRADIENT_PRIMARY,
                isDisabled: !this.username.trim() || !this.password.trim(),
                onButtonClick: () => this.handleLogin()
              })
            }
            .width('100%')
            .padding(24)
            .backgroundColor(AppColors.BG_SECONDARY)
            .borderRadius(24)
            .border({ width: 1, color: AppColors.BORDER })
            .shadow({
              radius: 20,
              color: AppColors.SHADOW_COLOR,
              offsetX: 0,
              offsetY: 10
            })
          }
          .padding({ left: 20, right: 20, bottom: 36 })
        }
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      LoadingOverlay({ isLoading: this.isLoading, message: '正在登录' })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private inputBlock(label: string, placeholder: string, value: string, isPassword: boolean, onChange: (value: string) => void) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')

      Row() {
        TextInput({ placeholder: placeholder, text: value })
          .type(isPassword && !this.showPassword ? InputType.Password : InputType.Normal)
          .layoutWeight(1)
          .height(52)
          .backgroundColor('transparent')
          .placeholderColor(AppColors.TEXT_TERTIARY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontSize(AppTypography.SIZE_BODY)
          .caretColor(AppColors.PRIMARY)
          .onChange(onChange)

        if (isPassword) {
          Text(this.showPassword ? '隐藏' : '显示')
            .fontSize(AppTypography.SIZE_CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              this.showPassword = !this.showPassword;
            })
        }
      }
      .width('100%')
      .padding({ left: 14, right: 14 })
      .backgroundColor(AppColors.BG_TERTIARY)
      .borderRadius(16)
      .border({
        width: 1,
        color: this.errorMessage ? AppColors.DANGER : AppColors.BORDER
      })
    }
  }

  private async handleLogin(): Promise<void> {
    if (!this.username.trim() || !this.password.trim()) {
      this.errorMessage = '请输入用户名和密码';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const user = await UserDao.getInstance().validateUser(this.username.trim(), this.password.trim());

      if (user) {
        AuthManager.getInstance().setCurrentUser(user);
        router.replaceUrl({ url: 'pages/MainPage' });
      } else {
        this.errorMessage = '用户名或密码错误';
      }
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '登录失败，请重试';
      console.error('Login error:', error);
    } finally {
      this.isLoading = false;
    }
  }
}
