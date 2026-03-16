import { router } from '@kit.ArkUI';
import { UserDao } from 'datastore';
import { AuthManager, Constants } from 'utils';
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
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [AppColors.BG_PRIMARY, 0],
            [AppColors.BG_SECONDARY, 0.5],
            [AppColors.BG_PRIMARY, 1]
          ]
        })

      // 装饰元素
      Circle()
        .width(300)
        .height(300)
        .fill(AppColors.PRIMARY)
        .opacity(0.05)
        .position({ x: -100, y: -100 })

      Circle()
        .width(200)
        .height(200)
        .fill(AppColors.PRIMARY)
        .opacity(0.08)
        .position({ x: 250, y: 600 })

      // 主内容
      Column() {
        Scroll() {
          Column({ space: 24 }) {
            // Logo
            Column({ space: 16 }) {
              Row() {
                Text('🏭')
                  .fontSize(64)
              }
              .width(120)
              .height(120)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(AppColors.PRIMARY + '20')
              .borderRadius(60)
              .border({ width: 2, color: AppColors.PRIMARY + '40' })

              Text('工业机器控制系统')
                .fontSize(AppTypography.SIZE_HEADLINE)
                .fontWeight(AppTypography.WEIGHT_BOLD)
                .fontColor(AppColors.TEXT_PRIMARY)

              Text('Industrial Machine Control System')
                .fontSize(AppTypography.SIZE_CAPTION)
                .fontColor(AppColors.TEXT_TERTIARY)
                .letterSpacing(1)
            }
            .margin({ top: 60, bottom: 40 })

            // 登录表单
            Column({ space: 16 }) {
              // 用户名
              Column({ space: 8 }) {
                Text('用户名')
                  .fontSize(AppTypography.SIZE_CAPTION)
                  .fontColor(AppColors.TEXT_SECONDARY)
                  .width('100%')

                Row() {
                  Text('👤')
                    .fontSize(20)
                    .margin({ left: 16 })

                  TextInput({ placeholder: '请输入用户名', text: this.username })
                    .layoutWeight(1)
                    .height(52)
                    .backgroundColor('transparent')
                    .placeholderColor(AppColors.TEXT_TERTIARY)
                    .fontColor(AppColors.TEXT_PRIMARY)
                    .fontSize(AppTypography.SIZE_BODY)
                    .caretColor(AppColors.PRIMARY)
                    .onChange((value) => {
                      this.username = value;
                      this.errorMessage = '';
                    })
                }
                .width('100%')
                .backgroundColor(AppColors.BG_TERTIARY)
                .borderRadius(12)
                .border({
                  width: 1,
                  color: this.errorMessage ? AppColors.DANGER : AppColors.BORDER
                })
              }

              // 密码
              Column({ space: 8 }) {
                Text('密码')
                  .fontSize(AppTypography.SIZE_CAPTION)
                  .fontColor(AppColors.TEXT_SECONDARY)
                  .width('100%')

                Row() {
                  Text('🔒')
                    .fontSize(20)
                    .margin({ left: 16 })

                  TextInput({ placeholder: '请输入密码', text: this.password })
                    .type(this.showPassword ? InputType.Normal : InputType.Password)
                    .layoutWeight(1)
                    .height(52)
                    .backgroundColor('transparent')
                    .placeholderColor(AppColors.TEXT_TERTIARY)
                    .fontColor(AppColors.TEXT_PRIMARY)
                    .fontSize(AppTypography.SIZE_BODY)
                    .caretColor(AppColors.PRIMARY)
                    .onChange((value) => {
                      this.password = value;
                      this.errorMessage = '';
                    })

                  Text(this.showPassword ? '👁️' : '👁️‍🗨️')
                    .fontSize(20)
                    .margin({ right: 16 })
                    .onClick(() => {
                      this.showPassword = !this.showPassword;
                    })
                }
                .width('100%')
                .backgroundColor(AppColors.BG_TERTIARY)
                .borderRadius(12)
                .border({
                  width: 1,
                  color: this.errorMessage ? AppColors.DANGER : AppColors.BORDER
                })
              }

              // 错误信息
              if (this.errorMessage) {
                Text(this.errorMessage)
                  .fontSize(AppTypography.SIZE_CAPTION)
                  .fontColor(AppColors.DANGER)
                  .width('100%')
              }

              // 登录按钮
              GradientButton({
                text: '登 录',
                icon: '🚀',
                gradientColors: AppColors.GRADIENT_PRIMARY,
                isDisabled: !this.username || !this.password,
                onButtonClick: () => this.handleLogin()
              })
                .margin({ top: 16 })
            }
            .width('100%')
            .padding(24)
            .backgroundColor(AppColors.BG_SECONDARY)
            .borderRadius(20)
            .border({ width: 1, color: AppColors.BORDER })
            .shadow({
              radius: 24,
              color: AppColors.SHADOW_COLOR,
              offsetX: 0,
              offsetY: 8
            })

            // 测试账号提示
            Column({ space: 8 }) {
              Text('测试账号')
                .fontSize(AppTypography.SIZE_CAPTION)
                .fontColor(AppColors.TEXT_TERTIARY)

              Row({ space: 24 }) {
                Column() {
                  Text('管理员')
                    .fontSize(AppTypography.SIZE_SMALL)
                    .fontColor(AppColors.PRIMARY)
                  Text('admin / admin123')
                    .fontSize(AppTypography.SIZE_SMALL)
                    .fontColor(AppColors.TEXT_SECONDARY)
                    .margin({ top: 4 })
                }

                Divider()
                  .vertical(true)
                  .height(30)
                  .color(AppColors.BORDER)

                Column() {
                  Text('普通用户')
                    .fontSize(AppTypography.SIZE_SMALL)
                    .fontColor(AppColors.WARNING)
                  Text('operator / operator123')
                    .fontSize(AppTypography.SIZE_SMALL)
                    .fontColor(AppColors.TEXT_SECONDARY)
                    .margin({ top: 4 })
                }
              }
            }
            .margin({ top: 32 })
          }
          .padding({ left: 24, right: 24, bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      LoadingOverlay({ isLoading: this.isLoading, message: '登录中...' })
    }
    .width('100%')
    .height('100%')
  }

  private async handleLogin(): Promise<void> {
    if (!this.username || !this.password) {
      this.errorMessage = '请输入用户名和密码';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const userDao = UserDao.getInstance();
      const user = await userDao.validateUser(this.username, this.password);

      if (user) {
        AuthManager.getInstance().setCurrentUser(user);
        router.replaceUrl({ url: 'pages/MainPage' });
      } else {
        this.errorMessage = '用户名或密码错误';
      }
    } catch (error) {
      this.errorMessage = '登录失败，请重试';
      console.error('Login error:', error);
    } finally {
      this.isLoading = false;
    }
  }
}
