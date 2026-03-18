/**
 * 应用颜色主题 - 简洁浅色工业风
 */
export class AppColors {
  // 背景色系
  static readonly BG_PRIMARY: string = '#F4F7FB';
  static readonly BG_SECONDARY: string = '#FFFFFF';
  static readonly BG_TERTIARY: string = '#EEF2F7';
  static readonly BG_ELEVATED: string = '#DCE5F0';

  // 主题色
  static readonly PRIMARY: string = '#2563EB';
  static readonly PRIMARY_LIGHT: string = '#5B8DEF';
  static readonly PRIMARY_DARK: string = '#1D4ED8';

  // 语义色
  static readonly SUCCESS: string = '#1F9D66';
  static readonly SUCCESS_LIGHT: string = '#39B980';
  static readonly WARNING: string = '#D97706';
  static readonly WARNING_LIGHT: string = '#F59E0B';
  static readonly DANGER: string = '#DC2626';
  static readonly DANGER_LIGHT: string = '#EF4444';

  // 文字色
  static readonly TEXT_PRIMARY: string = '#172033';
  static readonly TEXT_SECONDARY: string = '#52607A';
  static readonly TEXT_TERTIARY: string = '#7F8CA3';
  static readonly TEXT_ON_PRIMARY: string = '#FFFFFF';

  // 边框色
  static readonly BORDER: string = '#D8E0EA';
  static readonly BORDER_LIGHT: string = '#E8EEF5';

  // 渐变色
  static readonly GRADIENT_PRIMARY: [string, string] = ['#2563EB', '#1D4ED8'];
  static readonly GRADIENT_SUCCESS: [string, string] = ['#1F9D66', '#157347'];
  static readonly GRADIENT_DANGER: [string, string] = ['#DC2626', '#B91C1C'];

  // 状态栏透明度
  static readonly OVERLAY_LIGHT: string = 'rgba(37,99,235,0.08)';
  static readonly OVERLAY_DARK: string = 'rgba(15,23,42,0.24)';

  // 阴影
  static readonly SHADOW_COLOR: string = 'rgba(15,23,42,0.12)';

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
