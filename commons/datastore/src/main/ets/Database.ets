/**
 * @file Database.ets
 * @description 数据库管理模块 - 机器控制系统的核心数据持久化层
 *
 * 本文件实现了基于 HarmonyOS 关系型数据库 (RDB) 的数据存储功能，
 * 采用单例模式确保整个应用中只有一个数据库连接实例。
 *
 * 主要功能：
 * - 创建和管理 SQLite 数据库
 * - 定义设备表 (devices) 和用户表 (users) 的结构
 * - 提供示例数据的初始化
 * - 管理数据库连接的生命周期
 *
 * @author Machine Control System Team
 * @version 1.0.0
 */

import { relationalStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

/**
 * 数据库存储配置
 * @description 定义数据库文件名和安全级别
 *
 * @property name - 数据库文件名，存储在应用沙箱目录中
 * @property securityLevel - 安全级别，S1 表示低安全级别，适用于一般应用数据
 *
 * 安全级别说明：
 * - S1: 低级别，数据库在设备解锁后即可访问
 * - S2: 中级别，数据库仅在首次解锁后可访问
 * - S3: 高级别，数据库需要额外的访问控制
 * - S4: 最高级别，数据库需要严格的安全措施
 */
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'MachineControl.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

/**
 * 创建设备表的 SQL 语句
 * @description 定义 devices 表的结构，用于存储工业设备信息
 *
 * 表结构说明：
 * @field id          - 设备唯一标识符，作为主键 (如: DEV001)
 * @field name        - 设备名称 (如: 数控机床-A01)
 * @field address     - 设备所在详细地址
 * @field latitude    - 设备位置纬度坐标 (WGS84)
 * @field longitude   - 设备位置经度坐标 (WGS84)
 * @field status      - 设备运行状态 (0: 离线, 1: 运行中, 2: 维护中)
 * @field work_count  - 设备累计工作次数/产量
 * @field is_locked   - 设备锁定状态 (0: 未锁定, 1: 已锁定)
 * @field locked_by   - 锁定设备的用户名
 * @field locked_at   - 锁定时间戳 (Unix 毫秒)
 * @field updated_at  - 最后更新时间戳 (Unix 毫秒)
 */
const SQL_CREATE_DEVICES = `
  CREATE TABLE IF NOT EXISTS devices (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    status INTEGER DEFAULT 0,
    work_count INTEGER DEFAULT 0,
    is_locked INTEGER DEFAULT 0,
    locked_by TEXT,
    locked_at INTEGER,
    updated_at INTEGER
  )
`;

/**
 * 创建用户表的 SQL 语句
 * @description 定义 users 表的结构，用于存储系统用户信息
 *
 * 表结构说明：
 * @field id            - 用户唯一标识符，作为主键 (如: USR001)
 * @field username      - 用户登录名，必须唯一
 * @field password_hash - 密码哈希值 (注意: 生产环境应使用加密算法)
 * @field role          - 用户角色 ('admin': 管理员, 'user': 普通用户)
 * @field created_at    - 账号创建时间戳 (Unix 毫秒)
 */
const SQL_CREATE_USERS = `
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'user',
    created_at INTEGER
  )
`;

/**
 * 数据库管理类
 * @description 采用单例模式的数据库管理器，负责数据库的创建、连接和生命周期管理
 *
 * 使用方式:
 * ```typescript
 * // 1. 获取数据库单例
 * const db = Database.getInstance();
 *
 * // 2. 初始化数据库（通常在应用启动时调用）
 * await db.initialize(context);
 *
 * // 3. 获取 RDB 存储实例进行数据操作
 * const store = db.getStore();
 *
 * // 4. 应用退出时关闭数据库
 * await db.close();
 * ```
 *
 * 设计模式: 单例模式 (Singleton Pattern)
 * - 确保整个应用只有一个数据库连接
 * - 避免重复初始化和资源浪费
 * - 提供全局访问点
 */
export class Database {
  /**
   * 数据库单例实例
   * @description 存储全局唯一的 Database 实例
   * @private
   * @static
   */
  private static instance: Database | null = null;

  /**
   * RDB 存储实例
   * @description HarmonyOS 关系型数据库存储对象，用于执行 SQL 操作
   * @private
   */
  private rdbStore: relationalStore.RdbStore | null = null;

  /**
   * 初始化状态标志
   * @description 标记数据库是否已成功初始化，避免重复初始化
   * @private
   */
  private initialized: boolean = false;

  /**
   * 私有构造函数
   * @description 防止外部直接实例化，强制使用 getInstance() 获取单例
   * @private
   */
  private constructor() { }

  /**
   * 获取数据库单例实例
   * @description 返回全局唯一的 Database 实例，如果不存在则创建
   *
   * @returns {Database} 数据库管理器单例
   *
   * @example
  * const db = Database.getInstance();
   */
  static getInstance(): Database {
    // 懒加载：首次调用时才创建实例
    if (!Database.instance) {
      Database.instance = new Database();
    }
    return Database.instance;
  }

  /**
   * 初始化数据库
   * @description 创建数据库连接，执行建表语句，并插入示例数据
   *
   * 初始化流程：
   * 1. 检查是否已初始化，避免重复操作
   * 2. 获取 RDB 存储实例
   * 3. 创建 devices 表（如果不存在）
   * 4. 创建 users 表（如果不存在）
   * 5. 插入示例数据（如果表为空）
   *
   * @param {Context} context - HarmonyOS 应用上下文，用于获取应用沙箱路径
   * @returns {Promise<void>} 初始化完成的 Promise
   * @throws {Error} 数据库初始化失败时抛出异常
   *
   * @example
  * // 在 EntryAbility 的 onCreate 中调用
   * async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
   *     const db = Database.getInstance();
   *     await db.initialize(this.context);
   * }
   */
  async initialize(context: Context): Promise<void> {
    // 防止重复初始化
    if (this.initialized) {
      return;
    }

    try {
      // 步骤1: 获取或创建 RDB 存储实例
      // getRdbStore 会在应用沙箱目录中创建或打开数据库文件
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);

      // 步骤2: 执行建表 SQL - 创建设备表
      // IF NOT EXISTS 确保表不会被重复创建
      await this.rdbStore.executeSql(SQL_CREATE_DEVICES);

      // 步骤3: 执行建表 SQL - 创建用户表
      await this.rdbStore.executeSql(SQL_CREATE_USERS);

      // 步骤4: 插入示例数据（仅在首次运行时）
      await this.insertSampleData();

      // 标记初始化完成
      this.initialized = true;
      console.info('Database initialized successfully');
    } catch (error) {
      // 记录错误日志并向上抛出异常
      console.error('Failed to initialize database:', error);
      throw new Error(`Failed to initialize database: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 获取 RDB 存储实例
   * @description 返回底层的 RdbStore 对象，供 DAO 层执行数据库操作
   *
   * @returns {relationalStore.RdbStore} RDB 存储实例
   * @throws {Error} 如果数据库未初始化则抛出异常
   *
   * @example
  * const store = Database.getInstance().getStore();
   * const predicates = new relationalStore.RdbPredicates('devices');
   * const result = await store.query(predicates, ['id', 'name']);
   */
  getStore(): relationalStore.RdbStore {
    // 确保数据库已初始化
    if (!this.rdbStore) {
      throw new Error('Database not initialized');
    }
    return this.rdbStore;
  }

  /**
   * 插入示例数据
   * @description 在数据库首次创建时插入演示用的设备和用户数据
   *
   * 插入逻辑：
   * 1. 先查询 devices 表，检查是否已有数据
   * 2. 如果表不为空，说明已初始化过，直接返回
   * 3. 如果表为空，插入预设的设备数据和用户数据
   *
   * 注意事项：
   * - 此方法仅在首次运行时执行插入
   * - 使用 try-catch 确保异常安全
   * - ResultSet 在 finally 中关闭，确保资源释放
   *
   * @private
   * @returns {Promise<void>} 插入完成的 Promise
   */
  private async insertSampleData(): Promise<void> {
    // 安全检查：确保 rdbStore 存在
    if (!this.rdbStore) return;

    // 用于存储查询结果集，需要在 finally 中关闭
    let result: relationalStore.ResultSet | null = null;

    try {
      // 检查是否已有数据 - 查询 devices 表的 id 列
      const predicates = new relationalStore.RdbPredicates('devices');
      result = await this.rdbStore.query(predicates, ['id']);

      // 如果已存在数据，跳过插入步骤
      if (result.rowCount > 0) {
        return;
      }
    } catch (error) {
      // 查询失败时记录日志并返回，不阻塞应用启动
      console.error('Failed to query devices:', error);
      return;
    } finally {
      // 确保结果集被正确关闭，释放数据库资源
      if (result) {
        try {
          result.close();
        } catch (closeError) {
          console.error('Failed to close result set:', closeError);
        }
      }
    }

    /**
     * 示例设备数据数组
     * @description 预设的5台工业设备，分布在山东、江苏、安徽地区
     *
     * 设备状态说明:
     * - status 0: 离线/停机
     * - status 1: 正常运行
     * - status 2: 维护中
     *
     * 锁定状态说明:
     * - is_locked 0: 未锁定，可正常操作
     * - is_locked 1: 已锁定，需要解锁后才能操作
     */
    const devices: relationalStore.ValuesBucket[] = [
      {
        id: 'DEV001',                    // 设备编号
        name: '数控机床-A01',              // 设备名称
        address: '山东省枣庄市滕州市界河镇西万院村766号滕州市金果果蔬有限公司',  // 详细地址
        latitude: 35.0827,               // 纬度坐标
        longitude: 117.1536,             // 经度坐标
        status: 1,                       // 运行中
        work_count: 1523,                // 累计工作次数
        is_locked: 0,                    // 未锁定
        locked_by: '',                   // 锁定者（空）
        locked_at: 0,                    // 锁定时间（无）
        updated_at: Date.now()           // 当前时间戳
      },
      {
        id: 'DEV002',
        name: '激光切割机-B02',
        address: '山东省枣庄市滕州市龙阳镇工业园区88号华瑞机械制造有限公司',
        latitude: 35.1034,
        longitude: 117.0892,
        status: 2,                       // 维护中
        work_count: 892,
        is_locked: 0,
        locked_by: '',
        locked_at: 0,
        updated_at: Date.now()
      },
      {
        id: 'DEV003',
        name: '冲压机-C03',
        address: '山东省济宁市邹城市钢山街道工业北路158号鑫泰重工集团',
        latitude: 35.4053,
        longitude: 117.0073,
        status: 0,                       // 离线
        work_count: 2341,
        is_locked: 1,                    // 已锁定
        locked_by: 'admin',              // 被 admin 锁定
        locked_at: Date.now() - 86400000, // 锁定于1天前
        updated_at: Date.now()
      },
      {
        id: 'DEV004',
        name: '焊接机器人-D04',
        address: '江苏省徐州市铜山区高新技术产业开发区创业路66号徐工智能装备研究院',
        latitude: 34.2044,
        longitude: 117.2859,
        status: 1,                       // 运行中
        work_count: 4567,
        is_locked: 0,
        locked_by: '',
        locked_at: 0,
        updated_at: Date.now()
      },
      {
        id: 'DEV005',
        name: '注塑机-E05',
        address: '安徽省宿州市埇桥区经济开发区金海大道199号宿州精密模具产业园',
        latitude: 33.6376,
        longitude: 116.9883,
        status: 1,                       // 运行中
        work_count: 3298,
        is_locked: 0,
        locked_by: '',
        locked_at: 0,
        updated_at: Date.now()
      }
    ];

    // 批量插入设备数据
    try {
      for (const device of devices) {
        // insert 方法返回插入的行号，如果失败返回 -1
        await this.rdbStore.insert('devices', device);
      }
    } catch (error) {
      // 插入失败时记录日志，但不抛出异常，允许应用继续运行
      console.error('Failed to insert devices:', error);
    }

    /**
     * 示例用户数据数组
     * @description 预设的系统用户账号
     *
     * 用户角色说明:
     * - admin: 管理员，拥有所有权限
     * - user: 普通用户，只能查看和锁定自己负责的设备
     *
     * 安全提醒: 生产环境中密码应使用 bcrypt、SHA-256 等算法加密存储
     */
    const users: relationalStore.ValuesBucket[] = [
      {
        id: 'USR001',                    // 用户编号
        username: 'admin',               // 登录用户名
        password_hash: 'admin123',       // 密码（注意：生产环境应加密）
        role: 'admin',                   // 管理员角色
        created_at: Date.now()           // 创建时间
      },
      {
        id: 'USR002',
        username: 'operator',
        password_hash: 'operator123',
        role: 'user',                    // 普通用户角色
        created_at: Date.now()
      }
    ];

    // 批量插入用户数据
    try {
      for (const user of users) {
        await this.rdbStore.insert('users', user);
      }
    } catch (error) {
      console.error('Failed to insert users:', error);
    }

    // 记录成功日志
    console.info('Sample data inserted successfully');
  }

  /**
   * 关闭数据库连接
   * @description 释放数据库资源，通常在应用退出时调用
   *
   * 关闭流程：
   * 1. 将 rdbStore 引用置为 null
   * 2. 重置初始化标志
   *
   * 注意：关闭后如需再次使用，需重新调用 initialize()
   *
   * @returns {Promise<void>} 关闭完成的 Promise
   *
   * @example
  * // 在 EntryAbility 的 onDestroy 中调用
   * onDestroy(): void {
   *     Database.getInstance().close();
   * }
   */
  async close(): Promise<void> {
    if (this.rdbStore) {
      // 释放存储引用
      this.rdbStore = null;
      // 重置初始化状态，允许再次初始化
      this.initialized = false;
    }
  }
}
