import { router, promptAction } from '@kit.ArkUI';
import { UserDao, UserRole } from 'datastore';
import { AuthManager } from 'utils';
import { AppColors, AppTypography, GradientButton, LoadingOverlay } from 'uikit';

/**
 * 管理员新增用户页面
 */
@Entry
@Component
struct CreateUserPage {
  @State private username: string = '';
  @State private password: string = '';
  @State private confirmPassword: string = '';
  @State private role: UserRole = UserRole.USER;
  @State private showPassword: boolean = false;
  @State private isSubmitting: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (!AuthManager.getInstance().canLockDevice()) {
      promptAction.showToast({ message: '仅管理员可新增用户', duration: 2000 });
      router.back();
    }
  }

  build() {
    Stack() {
      Column({ space: 16 }) {
        this.navBar()

        Column({ space: 20 }) {
          Column({ space: 8 }) {
            Text('新增用户')
              .fontSize(AppTypography.SIZE_HEADLINE)
              .fontWeight(AppTypography.WEIGHT_BOLD)
              .fontColor(AppColors.TEXT_PRIMARY)

            Text('创建新的管理员或普通用户账号，当前版本仅维护账号、初始密码和角色。')
              .fontSize(AppTypography.SIZE_BODY)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          this.fieldBlock('用户名', '请输入用户名', this.username, (value: string) => {
            this.username = value;
            this.errorMessage = '';
          })

          this.passwordBlock('初始密码', '请输入 6-32 位密码', this.password, (value: string) => {
            this.password = value;
            this.errorMessage = '';
          })

          this.passwordBlock('确认密码', '请再次输入密码', this.confirmPassword, (value: string) => {
            this.confirmPassword = value;
            this.errorMessage = '';
          })

          this.roleBlock()

          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(AppTypography.SIZE_CAPTION)
              .fontColor(AppColors.DANGER)
              .width('100%')
          }

          GradientButton({
            text: this.isSubmitting ? '提交中' : '确认新增',
            gradientColors: AppColors.GRADIENT_PRIMARY,
            isDisabled: this.isSubmitting || !this.username.trim() || !this.password || !this.confirmPassword,
            onButtonClick: () => this.submit()
          })
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

      LoadingOverlay({ isLoading: this.isSubmitting, message: '正在创建用户' })
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
  private passwordBlock(label: string, placeholder: string, value: string, onChange: (value: string) => void) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')

      Row() {
        TextInput({ placeholder: placeholder, text: value })
          .type(this.showPassword ? InputType.Normal : InputType.Password)
          .layoutWeight(1)
          .height(52)
          .backgroundColor('transparent')
          .placeholderColor(AppColors.TEXT_TERTIARY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontSize(AppTypography.SIZE_BODY)
          .caretColor(AppColors.PRIMARY)
          .onChange(onChange)

        Text(this.showPassword ? '隐藏' : '显示')
          .fontSize(AppTypography.SIZE_CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            this.showPassword = !this.showPassword;
          })
      }
      .width('100%')
      .padding({ left: 14, right: 14 })
      .backgroundColor(AppColors.BG_TERTIARY)
      .borderRadius(16)
      .border({ width: 1, color: AppColors.BORDER })
    }
    .width('100%')
  }

  @Builder
  private roleBlock() {
    Column({ space: 10 }) {
      Text('角色')
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')

      Row({ space: 12 }) {
        this.roleChip('普通用户', UserRole.USER)
        this.roleChip('管理员', UserRole.ADMIN)
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private roleChip(label: string, role: UserRole) {
    Text(label)
      .fontSize(AppTypography.SIZE_BODY)
      .fontWeight(AppTypography.WEIGHT_MEDIUM)
      .fontColor(this.role === role ? AppColors.TEXT_ON_PRIMARY : AppColors.TEXT_PRIMARY)
      .layoutWeight(1)
      .height(48)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.role === role ? AppColors.PRIMARY : AppColors.BG_TERTIARY)
      .borderRadius(16)
      .border({ width: this.role === role ? 0 : 1, color: AppColors.BORDER })
      .onClick(() => {
        this.role = role;
      })
  }

  private validateInput(): string {
    const normalizedUsername = this.username.trim();

    if (!normalizedUsername) {
      return '请输入用户名';
    }

    if (normalizedUsername.length > 32 || /\s/.test(normalizedUsername)) {
      return '用户名不能包含空白，且长度不能超过 32 位';
    }

    if (this.password.length < 6 || this.password.length > 32) {
      return '密码长度需为 6-32 位';
    }

    if (this.password !== this.confirmPassword) {
      return '两次输入的密码不一致';
    }

    return '';
  }

  private async submit(): Promise<void> {
    const validationMessage = this.validateInput();
    if (validationMessage) {
      this.errorMessage = validationMessage;
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';

    try {
      const user = await UserDao.getInstance().createUser(this.username.trim(), this.password, this.role);
      promptAction.showToast({
        message: `${user.username} 已创建为${user.getRoleText()}`,
        duration: 2000
      });
      router.back();
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '新增用户失败，请稍后重试';
    } finally {
      this.isSubmitting = false;
    }
  }
}
