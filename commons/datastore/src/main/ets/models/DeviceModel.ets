/**
 * @file DeviceModel.ets
 * @description 设备数据模型模块 - 定义工业设备的数据结构和状态表示
 *
 * 本文件包含：
 * - DeviceStatus 枚举：定义设备的运行状态
 * - DeviceModel 类：设备数据的完整模型，包含位置、状态、锁定等信息
 *
 * 使用场景：
 * - 从数据库读取设备数据后转换为 DeviceModel 实例
 * - 在 UI 层显示设备信息
 * - 在地图上标注设备位置
 * - 设备锁定/解锁操作
 *
 * @author Machine Control System Team
 * @version 1.0.0
 */

/**
 * 设备状态枚举
 * @description 定义工业设备可能的运行状态
 *
 * 状态说明：
 * - OFFLINE (0): 设备离线，无法通信或已断电
 * - WORKING (1): 设备正在工作，正常运转中
 * - STANDBY (2): 设备待机，已启动但未执行任务
 *
 * @example
* // 检查设备是否在线工作
 * if (device.status === DeviceStatus.WORKING) {
 *     console.log('设备正在运行');
 * }
 */
export enum DeviceStatus {
  /** 离线状态 - 设备无法访问或已关机 */
  OFFLINE = 0,

  /** 工作中状态 - 设备正在执行生产任务 */
  WORKING = 1,

  /** 待机状态 - 设备已启动，等待任务分配 */
  STANDBY = 2
}

/**
 * 设备模型初始化选项接口
 * @description 用于 DeviceModel 构造函数的参数类型定义，解决 ArkTS 对象字面量类型检查
 */
export interface DeviceModelOptions {
  id?: string;
  name?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  status?: DeviceStatus;
  workCount?: number;
  isLocked?: boolean;
  lockedBy?: string;
  lockedAt?: number;
  updatedAt?: number;
}

/**
 * 设备数据模型类
 * @description 表示一台工业设备的完整信息，包括基本信息、位置坐标、运行状态和锁定状态
 *
 * 数据字段分类：
 * 1. 基本信息：id, name, address
 * 2. 位置信息：latitude, longitude（用于地图显示）
 * 3. 状态信息：status, workCount
 * 4. 锁定信息：isLocked, lockedBy, lockedAt
 * 5. 时间信息：updatedAt
 *
 * @example
* // 创建新的设备模型实例
 * const device = new DeviceModel({
 *     id: 'DEV001',
 *     name: '数控机床-A01',
 *     status: DeviceStatus.WORKING,
 *     latitude: 35.0827,
 *     longitude: 117.1536
 * });
 *
 * // 获取状态显示文本
 * console.log(device.getStatusText()); // 输出: "工作中"
 *
 * // 获取状态对应的颜色（用于UI显示）
 * console.log(device.getStatusColor()); // 输出: "#3FB950"
 */
export class DeviceModel {
  /**
   * 设备唯一标识符
   * @description 设备的全局唯一ID，格式通常为 "DEV" + 3位数字
   * @example "DEV001", "DEV002"
   */
  id: string = '';

  /**
   * 设备名称
   * @description 设备的显示名称，包含设备类型和编号
   * @example "数控机床-A01", "激光切割机-B02"
   */
  name: string = '';

  /**
   * 设备详细地址
   * @description 设备所在的完整物理地址，包含省市区街道门牌号
   * @example "山东省枣庄市滕州市界河镇西万院村766号"
   */
  address: string = '';

  /**
   * 纬度坐标
   * @description 设备位置的纬度，采用 WGS84 坐标系
   * @description 有效范围：-90 到 90
   * @example 35.0827 (山东滕州)
   */
  latitude: number = 0;

  /**
   * 经度坐标
   * @description 设备位置的经度，采用 WGS84 坐标系
   * @description 有效范围：-180 到 180
   * @example 117.1536 (山东滕州)
   */
  longitude: number = 0;

  /**
   * 设备运行状态
   * @description 表示设备当前的运行状况
   * @see DeviceStatus 状态枚举定义
   * @default DeviceStatus.OFFLINE
   */
  status: DeviceStatus = DeviceStatus.OFFLINE;

  /**
   * 累计工作次数/产量
   * @description 设备自投入使用以来完成的工作周期数或生产件数
   * @example 1523 (已完成1523次加工)
   */
  workCount: number = 0;

  /**
   * 锁定状态标志
   * @description 表示设备是否被管理员锁定
   * - true: 设备已锁定，禁止操作
   * - false: 设备正常，可以操作
   *
   * 锁定场景：
   * - 设备维护期间
   * - 发现异常需要检查
   * - 安全检查未通过
   */
  isLocked: boolean = false;

  /**
   * 锁定操作者用户名
   * @description 执行锁定操作的用户名，用于追溯责任
   * @example "admin", "operator"
   */
  lockedBy: string = '';

  /**
   * 锁定时间戳
   * @description 设备被锁定的时间，Unix 毫秒时间戳
   * @example 1704556800000 (2024-01-07 00:00:00 UTC)
   */
  lockedAt: number = 0;

  /**
   * 最后更新时间戳
   * @description 设备信息最后一次更新的时间，Unix 毫秒时间戳
   * @description 用于数据同步和缓存判断
   */
  updatedAt: number = 0;

  /**
   * 构造函数
   * @description 创建 DeviceModel 实例，支持部分初始化
   *
   * @param {Partial<DeviceModel>} [init] - 可选的初始化参数对象
   *        可以只传入部分属性，未传入的属性使用默认值
   *
   * 注意事项：
   * - ArkTS 不支持 Object.assign()，因此采用手动属性赋值
   * - 每个属性都进行 undefined 检查，确保只覆盖明确传入的值
   *
   * @example
  * // 使用部分属性创建实例
   * const device1 = new DeviceModel({
   *     id: 'DEV001',
   *     name: '测试设备'
   * });
   *
   * // 创建空实例（使用所有默认值）
   * const device2 = new DeviceModel();
   *
   * // 从数据库记录创建实例
   * const device3 = new DeviceModel({
   *     id: row.id,
   *     name: row.name,
   *     status: row.status as DeviceStatus,
   *     isLocked: row.is_locked === 1
   * });
   */
  constructor(init?: DeviceModelOptions) {
    if (init) {
      // ArkTS 不支持 Object.assign()，需手动逐个赋值
      // 每个属性检查 undefined，避免覆盖默认值
      if (init.id !== undefined) this.id = init.id;
      if (init.name !== undefined) this.name = init.name;
      if (init.address !== undefined) this.address = init.address;
      if (init.latitude !== undefined) this.latitude = init.latitude;
      if (init.longitude !== undefined) this.longitude = init.longitude;
      if (init.status !== undefined) this.status = init.status;
      if (init.workCount !== undefined) this.workCount = init.workCount;
      if (init.isLocked !== undefined) this.isLocked = init.isLocked;
      if (init.lockedBy !== undefined) this.lockedBy = init.lockedBy;
      if (init.lockedAt !== undefined) this.lockedAt = init.lockedAt;
      if (init.updatedAt !== undefined) this.updatedAt = init.updatedAt;
    }
  }

  /**
   * 获取设备状态的显示文本
   * @description 根据设备的锁定状态和运行状态，返回用户友好的中文描述
   *
   * 状态优先级：
   * 1. 如果设备被锁定，优先显示 "已锁定"（无论运行状态如何）
   * 2. 否则根据 status 字段显示对应状态文本
   *
   * @returns {string} 状态文本
   *          - "已锁定" - 设备处于锁定状态
   *          - "工作中" - 设备正在运行
   *          - "待机"   - 设备待机等待
   *          - "离线"   - 设备离线或未知状态
   *
   * @example
  * const device = new DeviceModel({ status: DeviceStatus.WORKING });
   * console.log(device.getStatusText()); // "工作中"
   *
   * device.isLocked = true;
   * console.log(device.getStatusText()); // "已锁定"
   */
  getStatusText(): string {
    // 锁定状态优先级最高
    if (this.isLocked) {
      return '已锁定';
    }

    // 根据运行状态返回对应文本
    switch (this.status) {
      case DeviceStatus.WORKING:
        return '工作中';
      case DeviceStatus.STANDBY:
        return '待机';
      default:
      // OFFLINE 或其他未知状态
        return '离线';
    }
  }

  /**
   * 获取设备状态的显示颜色
   * @description 根据设备状态返回对应的十六进制颜色值，用于 UI 样式设置
   *
   * 颜色定义（采用 GitHub 风格配色）：
   * - 已锁定: #F85149 (红色) - 表示警告/禁用状态
   * - 工作中: #3FB950 (绿色) - 表示正常运行
   * - 待机:   #F0883E (橙色) - 表示等待/注意状态
   * - 离线:   #8B949E (灰色) - 表示不可用
   *
   * @returns {string} 十六进制颜色字符串，格式为 "#RRGGBB"
   *
   * @example
  * // 在 ArkUI 中使用
   * Text(device.getStatusText())
   *     .fontColor(device.getStatusColor())
   *
   * // 条件样式
   * Circle()
   *     .fill(device.getStatusColor())
   *     .width(10)
   *     .height(10)
   */
  getStatusColor(): string {
    // 锁定状态使用红色警示
    if (this.isLocked) {
      return '#F85149';  // 红色 - 警告/锁定
    }

    // 根据运行状态返回对应颜色
    switch (this.status) {
      case DeviceStatus.WORKING:
        return '#3FB950';  // 绿色 - 正常运行
      case DeviceStatus.STANDBY:
        return '#F0883E';  // 橙色 - 待机等待
      default:
        return '#8B949E';  // 灰色 - 离线/不可用
    }
  }
}
