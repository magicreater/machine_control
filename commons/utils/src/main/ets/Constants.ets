/**
 * 全局常量
 */
export class Constants {
  // 刷新间隔（毫秒）
  static readonly REFRESH_INTERVAL: number = 30000; // 30秒

  // 页面路由
  static readonly ROUTE_LOGIN: string = 'pages/LoginPage';
  static readonly ROUTE_MAIN: string = 'pages/MainPage';
  static readonly ROUTE_DEVICE_DETAIL: string = 'pages/DeviceDetailPage';
  static readonly ROUTE_LOCK_CONTROL: string = 'pages/LockControlPage';

  // 存储键
  static readonly KEY_CURRENT_USER: string = 'current_user';
  static readonly KEY_USER_TOKEN: string = 'user_token';
  static readonly KEY_REFRESH_INTERVAL: string = 'refresh_interval';

  // 动画时长（毫秒）
  static readonly ANIMATION_DURATION_SHORT: number = 200;
  static readonly ANIMATION_DURATION_NORMAL: number = 300;
  static readonly ANIMATION_DURATION_LONG: number = 500;

  // 滑动确认距离阈值（百分比）
  static readonly SLIDE_THRESHOLD: number = 0.8;

  // 地图配置
  static readonly MAP_DEFAULT_ZOOM: number = 10;
  static readonly MAP_DEFAULT_CENTER_LAT: number = 35.0827;
  static readonly MAP_DEFAULT_CENTER_LNG: number = 117.1536;
}
