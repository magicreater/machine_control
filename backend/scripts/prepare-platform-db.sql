USE platform;

SET @schema_name := DATABASE();

SET @ddl := (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @schema_name
        AND TABLE_NAME = 'details'
        AND COLUMN_NAME = 'latitude'
    ),
    'SELECT ''details.latitude already exists''',
    'ALTER TABLE details ADD COLUMN latitude DECIMAL(10,6) NULL COMMENT ''设备纬度'''
  )
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @schema_name
        AND TABLE_NAME = 'details'
        AND COLUMN_NAME = 'longitude'
    ),
    'SELECT ''details.longitude already exists''',
    'ALTER TABLE details ADD COLUMN longitude DECIMAL(10,6) NULL COMMENT ''设备经度'''
  )
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @schema_name
        AND TABLE_NAME = 'details'
        AND COLUMN_NAME = 'isLocked'
    ),
    'SELECT ''details.isLocked already exists''',
    'ALTER TABLE details ADD COLUMN isLocked TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''显式锁定状态'''
  )
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @schema_name
        AND TABLE_NAME = 'details'
        AND COLUMN_NAME = 'lockedBy'
    ),
    'SELECT ''details.lockedBy already exists''',
    'ALTER TABLE details ADD COLUMN lockedBy VARCHAR(255) NULL COMMENT ''最后锁定操作者'''
  )
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @schema_name
        AND TABLE_NAME = 'details'
        AND COLUMN_NAME = 'lockedAt'
    ),
    'SELECT ''details.lockedAt already exists''',
    'ALTER TABLE details ADD COLUMN lockedAt BIGINT NULL COMMENT ''锁定时间戳(毫秒)'''
  )
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = @schema_name
        AND TABLE_NAME = 'details'
        AND COLUMN_NAME = 'updatedAt'
    ),
    'SELECT ''details.updatedAt already exists''',
    'ALTER TABLE details ADD COLUMN updatedAt BIGINT NULL COMMENT ''最后更新时间戳(毫秒)'''
  )
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM information_schema.STATISTICS
      WHERE TABLE_SCHEMA = @schema_name
        AND TABLE_NAME = 'details'
        AND COLUMN_NAME = 'equipmentId'
        AND NON_UNIQUE = 0
    ),
    'SELECT ''details unique index on equipmentId already exists''',
    'ALTER TABLE details ADD UNIQUE KEY uq_details_equipmentId (equipmentId)'
  )
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

INSERT INTO admin (username, password, name, phone, email, role, avatar)
VALUES ('admin', 'admin123', 'admin', NULL, NULL, 'ADMIN', NULL)
ON DUPLICATE KEY UPDATE
  password = VALUES(password),
  name = VALUES(name),
  role = VALUES(role);

INSERT INTO user (username, password, name, phone, email, role, avatar)
VALUES ('operator', 'operator123', 'operator', NULL, NULL, 'USER', NULL)
ON DUPLICATE KEY UPDATE
  password = VALUES(password),
  name = VALUES(name),
  role = VALUES(role);

INSERT INTO details (
  equipmentId,
  model,
  location,
  lck,
  status,
  time,
  total,
  bad,
  rottencount,
  greenSkin,
  mechanicalDamage,
  sprouted,
  lastUpdate,
  latitude,
  longitude,
  isLocked,
  lockedBy,
  lockedAt,
  updatedAt
)
VALUES
  (
    'DEV001',
    '土豆筛选设备-A01',
    '山东省枣庄市滕州市界河镇西万院村766号滕州市金果果蔬有限公司',
    '0',
    'run',
    0,
    1523,
    0,
    0,
    0,
    0,
    0,
    DATE_FORMAT(CURRENT_TIMESTAMP, '%Y-%m-%d %H:%i:%s'),
    35.082700,
    117.153600,
    0,
    '',
    0,
    UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000
  ),
  (
    'DEV002',
    '土豆筛选设备-B02',
    '山东省枣庄市滕州市龙阳镇工业园区88号华瑞机械制造有限公司',
    '0',
    'standby',
    0,
    892,
    0,
    0,
    0,
    0,
    0,
    DATE_FORMAT(CURRENT_TIMESTAMP, '%Y-%m-%d %H:%i:%s'),
    35.103400,
    117.089200,
    0,
    '',
    0,
    UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000
  ),
  (
    'DEV003',
    '土豆筛选设备-C03',
    '山东省济宁市邹城市钢山街道工业北路158号鑫泰重工集团',
    '1',
    'stop',
    0,
    2341,
    0,
    0,
    0,
    0,
    0,
    DATE_FORMAT(DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY), '%Y-%m-%d %H:%i:%s'),
    35.405300,
    117.007300,
    1,
    'admin',
    UNIX_TIMESTAMP(DATE_SUB(CURRENT_TIMESTAMP(3), INTERVAL 1 DAY)) * 1000,
    UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000
  ),
  (
    'DEV004',
    '土豆筛选设备-D04',
    '江苏省徐州市铜山区高新技术产业开发区创业路66号徐工智能装备研究院',
    '0',
    'run',
    0,
    4567,
    0,
    0,
    0,
    0,
    0,
    DATE_FORMAT(CURRENT_TIMESTAMP, '%Y-%m-%d %H:%i:%s'),
    34.204400,
    117.285900,
    0,
    '',
    0,
    UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000
  ),
  (
    'DEV005',
    '土豆筛选设备-E05',
    '安徽省宿州市埇桥区经济开发区金海大道199号宿州精密模具产业园',
    '0',
    'run',
    0,
    3298,
    0,
    0,
    0,
    0,
    0,
    DATE_FORMAT(CURRENT_TIMESTAMP, '%Y-%m-%d %H:%i:%s'),
    33.637600,
    116.988300,
    0,
    '',
    0,
    UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000
  )
ON DUPLICATE KEY UPDATE
  model = VALUES(model),
  location = VALUES(location),
  lck = VALUES(lck),
  status = VALUES(status),
  time = VALUES(time),
  total = VALUES(total),
  latitude = VALUES(latitude),
  longitude = VALUES(longitude),
  isLocked = VALUES(isLocked),
  lockedBy = VALUES(lockedBy),
  lockedAt = VALUES(lockedAt),
  updatedAt = VALUES(updatedAt),
  lastUpdate = VALUES(lastUpdate);
