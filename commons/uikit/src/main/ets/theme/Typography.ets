/**
 * 应用字体样式
 */
export class AppTypography {
  // 字体大小
  static readonly SIZE_DISPLAY: number = 36;    // 大标题
  static readonly SIZE_HEADLINE: number = 28;   // 页面标题
  static readonly SIZE_TITLE: number = 22;      // 卡片标题
  static readonly SIZE_SUBTITLE: number = 18;   // 副标题
  static readonly SIZE_BODY: number = 16;       // 正文
  static readonly SIZE_CAPTION: number = 14;    // 说明文字
  static readonly SIZE_SMALL: number = 12;      // 小字

  // 字体粗细
  static readonly WEIGHT_BOLD: FontWeight = FontWeight.Bold;
  static readonly WEIGHT_MEDIUM: FontWeight = FontWeight.Medium;
  static readonly WEIGHT_REGULAR: FontWeight = FontWeight.Regular;
  static readonly WEIGHT_LIGHT: FontWeight = FontWeight.Lighter;

  // 行高
  static readonly LINE_HEIGHT_TIGHT: number = 1.2;
  static readonly LINE_HEIGHT_NORMAL: number = 1.5;
  static readonly LINE_HEIGHT_RELAXED: number = 1.8;
}
