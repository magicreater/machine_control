CREATE DATABASE IF NOT EXISTS machine_control
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'machine_control_app'@'%' IDENTIFIED BY 'change_me';
GRANT ALL PRIVILEGES ON machine_control.* TO 'machine_control_app'@'%';
FLUSH PRIVILEGES;

USE machine_control;

CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(32) PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  password_hash VARCHAR(128) NOT NULL,
  role VARCHAR(16) NOT NULL DEFAULT 'user',
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS devices (
  id VARCHAR(32) PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  address VARCHAR(255) NOT NULL,
  latitude DECIMAL(10, 6) NOT NULL,
  longitude DECIMAL(10, 6) NOT NULL,
  status INT NOT NULL DEFAULT 0,
  work_count INT NOT NULL DEFAULT 0,
  is_locked TINYINT(1) NOT NULL DEFAULT 0,
  locked_by VARCHAR(64) NOT NULL DEFAULT '',
  locked_at BIGINT NOT NULL DEFAULT 0,
  updated_at BIGINT NOT NULL
);

INSERT INTO users (id, username, password_hash, role, created_at)
VALUES
  ('USR001', 'admin', 'admin123', 'admin', UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000),
  ('USR002', 'operator', 'operator123', 'user', UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000)
ON DUPLICATE KEY UPDATE
  password_hash = VALUES(password_hash),
  role = VALUES(role);

INSERT INTO devices (id, name, address, latitude, longitude, status, work_count, is_locked, locked_by, locked_at, updated_at)
VALUES
  ('DEV001', '数控机床-A01', '山东省枣庄市滕州市界河镇西万院村766号滕州市金果果蔬有限公司', 35.082700, 117.153600, 1, 1523, 0, '', 0, UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000),
  ('DEV002', '激光切割机-B02', '山东省枣庄市滕州市龙阳镇工业园区88号华瑞机械制造有限公司', 35.103400, 117.089200, 2, 892, 0, '', 0, UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000),
  ('DEV003', '冲压机-C03', '山东省济宁市邹城市钢山街道工业北路158号鑫泰重工集团', 35.405300, 117.007300, 0, 2341, 1, 'admin', UNIX_TIMESTAMP(DATE_SUB(CURRENT_TIMESTAMP(3), INTERVAL 1 DAY)) * 1000, UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000),
  ('DEV004', '焊接机器人-D04', '江苏省徐州市铜山区高新技术产业开发区创业路66号徐工智能装备研究院', 34.204400, 117.285900, 1, 4567, 0, '', 0, UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000),
  ('DEV005', '注塑机-E05', '安徽省宿州市埇桥区经济开发区金海大道199号宿州精密模具产业园', 33.637600, 116.988300, 1, 3298, 0, '', 0, UNIX_TIMESTAMP(CURRENT_TIMESTAMP(3)) * 1000)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  address = VALUES(address),
  latitude = VALUES(latitude),
  longitude = VALUES(longitude),
  status = VALUES(status),
  work_count = VALUES(work_count),
  is_locked = VALUES(is_locked),
  locked_by = VALUES(locked_by),
  locked_at = VALUES(locked_at),
  updated_at = VALUES(updated_at);
