/**
 * @file UserModel.ets
 * @description 用户数据模型模块 - 定义系统用户的数据结构和权限控制
 *
 * 本文件包含：
 * - UserRole 枚举：定义用户角色类型
 * - UserModel 类：用户数据的完整模型，包含身份信息和权限判断
 *
 * 权限模型说明：
 * - 系统采用基于角色的访问控制 (RBAC)
 * - 管理员 (ADMIN): 拥有设备锁定/解锁权限
 * - 普通用户 (USER): 只能查看设备信息
 *
 * 使用场景：
 * - 用户登录验证
 * - 权限检查（是否可以锁定设备）
 * - 用户信息展示
 *
 * @author Machine Control System Team
 * @version 1.0.0
 */

/**
 * 用户角色枚举
 * @description 定义系统中用户的角色类型，用于权限控制
 *
 * 角色说明：
 * - ADMIN: 管理员角色，拥有完整的设备管理权限
 *   - 可以查看所有设备信息
 *   - 可以锁定/解锁设备
 *   - 可以修改设备状态
 *
 * - USER: 普通用户角色，仅有只读权限
 *   - 可以查看设备信息
 *   - 可以查看设备位置
 *   - 不能执行锁定操作
 *
 * @example
* // 检查用户角色
 * if (user.role === UserRole.ADMIN) {
 *     console.log('用户是管理员');
 * }
 *
 * // 根据角色显示不同UI
 * if (currentUser.role === UserRole.ADMIN) {
 *     // 显示锁定按钮
 * }
 */
export enum UserRole {
  /**
   * 管理员角色
   * @description 拥有设备锁定/解锁权限，可执行敏感操作
   */
  ADMIN = 'admin',

  /**
   * 普通用户角色
   * @description 只能查看设备信息，无法执行锁定操作
   */
  USER = 'user'
}

/**
 * 用户模型初始化选项接口
 * @description 用于 UserModel 构造函数的参数类型定义，解决 ArkTS 对象字面量类型检查
 */
export interface UserModelOptions {
  id?: string;
  username?: string;
  passwordHash?: string;
  role?: UserRole;
  createdAt?: number;
}

/**
 * 用户数据模型类
 * @description 表示系统中一个用户账号的完整信息，包含身份验证和权限判断功能
 *
 * 数据字段分类：
 * 1. 身份信息：id, username
 * 2. 安全信息：passwordHash（密码哈希值）
 * 3. 权限信息：role
 * 4. 时间信息：createdAt
 *
 * 安全注意事项：
 * - passwordHash 在生产环境中应使用 bcrypt、SHA-256 等算法加密
 * - 不应在日志中输出密码相关字段
 * - 密码验证应在服务端进行
 *
 * @example
* // 创建新用户模型实例
 * const user = new UserModel({
 *     id: 'USR001',
 *     username: 'admin',
 *     role: UserRole.ADMIN
 * });
 *
 * // 检查用户权限
 * if (user.canLockDevice()) {
 *     // 允许执行锁定操作
 * }
 *
 * // 获取角色显示文本
 * console.log(user.getRoleText()); // 输出: "管理员"
 */
export class UserModel {
  /**
   * 用户唯一标识符
   * @description 用户的全局唯一ID，格式通常为 "USR" + 3位数字
   * @example "USR001", "USR002"
   */
  id: string = '';

  /**
   * 用户登录名
   * @description 用户用于登录系统的唯一用户名
   * @description 在数据库中设置了 UNIQUE 约束，确保不重复
   * @example "admin", "operator", "zhang_wei"
   */
  username: string = '';

  /**
   * 密码哈希值
   * @description 用户密码的加密存储值
   *
   * 安全说明：
   * - 当前版本为演示目的，存储的是明文密码
   * - 生产环境必须使用安全的哈希算法（如 bcrypt、PBKDF2）
   * - 哈希时应加入随机盐值 (salt)
   * - 永远不要在日志或错误信息中输出此字段
   *
   * @example
  * // 生产环境示例（伪代码）
   * // this.passwordHash = bcrypt.hash(plainPassword, saltRounds);
   */
  passwordHash: string = '';

  /**
   * 用户角色
   * @description 决定用户在系统中的权限级别
   * @see UserRole 角色枚举定义
   * @default UserRole.USER 默认为普通用户
   */
  role: UserRole = UserRole.USER;

  /**
   * 账号创建时间戳
   * @description 用户账号创建的时间，Unix 毫秒时间戳
   * @description 用于账号管理和审计
   * @example 1704556800000 (2024-01-07 00:00:00 UTC)
   */
  createdAt: number = 0;

  /**
   * 构造函数
   * @description 创建 UserModel 实例，支持部分初始化
   *
   * @param {Partial<UserModel>} [init] - 可选的初始化参数对象
   *        可以只传入部分属性，未传入的属性使用默认值
   *
   * 注意事项：
   * - ArkTS 不支持 Object.assign()，因此采用手动属性赋值
   * - 每个属性都进行 undefined 检查，确保只覆盖明确传入的值
   *
   * @example
  * // 从登录响应创建用户实例
   * const user = new UserModel({
   *     id: response.userId,
   *     username: response.username,
   *     role: response.role as UserRole
   * });
   *
   * // 从数据库记录创建实例
   * const user = new UserModel({
   *     id: row.id,
   *     username: row.username,
   *     passwordHash: row.password_hash,
   *     role: row.role as UserRole,
   *     createdAt: row.created_at
   * });
   */
  constructor(init?: UserModelOptions) {
    if (init) {
      // ArkTS 不支持 Object.assign()，需手动逐个赋值
      // 每个属性检查 undefined，避免覆盖默认值
      if (init.id !== undefined) this.id = init.id;
      if (init.username !== undefined) this.username = init.username;
      if (init.passwordHash !== undefined) this.passwordHash = init.passwordHash;
      if (init.role !== undefined) this.role = init.role;
      if (init.createdAt !== undefined) this.createdAt = init.createdAt;
    }
  }

  /**
   * 检查用户是否有设备锁定权限
   * @description 判断当前用户是否可以执行设备锁定/解锁操作
   *
   * 权限规则：
   * - 只有 ADMIN 角色的用户可以锁定设备
   * - 普通 USER 角色无此权限
   *
   * 使用场景：
   * - 在 UI 层决定是否显示锁定按钮
   * - 在执行锁定操作前进行权限验证
   * - 在服务端 API 中进行权限检查
   *
   * @returns {boolean} 是否有锁定权限
   *          - true: 用户是管理员，可以锁定设备
   *          - false: 用户是普通用户，不能锁定设备
   *
   * @example
  * // 在 UI 中控制按钮显示
   * if (currentUser.canLockDevice()) {
   *     Button('锁定设备')
   *         .onClick(() => this.lockDevice(deviceId))
   * }
   *
   * // 在操作前验证权限
   * lockDevice(deviceId: string): void {
   *     if (!this.currentUser.canLockDevice()) {
   *         throw new Error('无权限执行此操作');
   *     }
   *     // 执行锁定逻辑...
   * }
   */
  canLockDevice(): boolean {
    return this.role === UserRole.ADMIN;
  }

  /**
   * 获取用户角色的显示文本
   * @description 将角色枚举值转换为用户友好的中文描述
   *
   * 转换规则：
   * - ADMIN -> "管理员"
   * - USER  -> "普通用户"
   *
   * @returns {string} 角色的中文显示文本
   *
   * @example
  * // 在用户信息页面显示
   * Text(`角色: ${user.getRoleText()}`)
   *
   * // 在列表中显示用户角色
   * ListItem() {
   *     Row() {
   *         Text(user.username)
   *         Text(user.getRoleText())
   *             .fontColor(user.role === UserRole.ADMIN ? '#3FB950' : '#8B949E')
   *     }
   * }
   */
  getRoleText(): string {
    return this.role === UserRole.ADMIN ? '管理员' : '普通用户';
  }
}
