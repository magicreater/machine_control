/**
 * 应用颜色主题 - 深色科技风
 */
export class AppColors {
  // 背景色系
  static readonly BG_PRIMARY: string = '#0D1117';       // 主背景
  static readonly BG_SECONDARY: string = '#161B22';     // 卡片背景
  static readonly BG_TERTIARY: string = '#21262D';      // 次级背景
  static readonly BG_ELEVATED: string = '#30363D';      // 提升背景

  // 主题色
  static readonly PRIMARY: string = '#00D4FF';          // 科技蓝
  static readonly PRIMARY_LIGHT: string = '#58E1FF';    // 浅科技蓝
  static readonly PRIMARY_DARK: string = '#00A8CC';     // 深科技蓝

  // 语义色
  static readonly SUCCESS: string = '#3FB950';          // 运行中/成功
  static readonly SUCCESS_LIGHT: string = '#56D364';    // 浅成功
  static readonly WARNING: string = '#F0883E';          // 待机/警告
  static readonly WARNING_LIGHT: string = '#FFAB55';    // 浅警告
  static readonly DANGER: string = '#F85149';           // 锁定/离线/错误
  static readonly DANGER_LIGHT: string = '#FF6B6B';     // 浅危险

  // 文字色
  static readonly TEXT_PRIMARY: string = '#E6EDF3';     // 主文字
  static readonly TEXT_SECONDARY: string = '#8B949E';   // 次文字
  static readonly TEXT_TERTIARY: string = '#6E7681';    // 三级文字
  static readonly TEXT_ON_PRIMARY: string = '#FFFFFF';  // 主色上的文字

  // 边框色
  static readonly BORDER: string = '#30363D';           // 边框
  static readonly BORDER_LIGHT: string = '#3D444D';     // 浅边框

  // 渐变色
  static readonly GRADIENT_PRIMARY: [string, string] = ['#00D4FF', '#0066FF'];  // 主渐变
  static readonly GRADIENT_SUCCESS: [string, string] = ['#3FB950', '#2EA043'];  // 成功渐变
  static readonly GRADIENT_DANGER: [string, string] = ['#F85149', '#DA3633'];   // 危险渐变

  // 状态栏透明度
  static readonly OVERLAY_LIGHT: string = 'rgba(255,255,255,0.05)';
  static readonly OVERLAY_DARK: string = 'rgba(0,0,0,0.3)';

  // 阴影
  static readonly SHADOW_COLOR: string = 'rgba(0,0,0,0.3)';

  /**
   * 获取状态对应的颜色
   */
  static getStatusColor(status: number, isLocked: boolean): string {
    if (isLocked) return AppColors.DANGER;
    switch (status) {
      case 1: return AppColors.SUCCESS;
      case 2: return AppColors.WARNING;
      default: return AppColors.TEXT_TERTIARY;
    }
  }
}
