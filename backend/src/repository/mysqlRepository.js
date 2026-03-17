import mysql from "mysql2/promise";

function mapDeviceRow(row) {
  return {
    id: row.id,
    name: row.name,
    address: row.address,
    latitude: Number(row.latitude),
    longitude: Number(row.longitude),
    status: Number(row.status),
    workCount: Number(row.work_count),
    isLocked: row.is_locked === 1,
    lockedBy: row.locked_by ?? "",
    lockedAt: Number(row.locked_at ?? 0),
    updatedAt: Number(row.updated_at ?? 0)
  };
}

export class MysqlRepository {
  constructor(config) {
    this.pool = mysql.createPool({
      host: config.mysqlHost,
      port: config.mysqlPort,
      database: config.mysqlDatabase,
      user: config.mysqlUser,
      password: config.mysqlPassword,
      waitForConnections: true,
      connectionLimit: 10,
      namedPlaceholders: true
    });
  }

  async validateUser(username, password) {
    const [rows] = await this.pool.execute(
      `SELECT id, username, role
       FROM users
       WHERE username = ? AND password_hash = ?
       LIMIT 1`,
      [username, password]
    );
    const user = rows[0];
    return user
      ? {
          id: user.id,
          username: user.username,
          role: user.role
        }
      : null;
  }

  async getAllDevices() {
    const [rows] = await this.pool.execute(
      `SELECT id, name, address, latitude, longitude, status, work_count, is_locked, locked_by, locked_at, updated_at
       FROM devices
       ORDER BY id ASC`
    );
    return rows.map(mapDeviceRow);
  }

  async getDeviceById(deviceId) {
    const [rows] = await this.pool.execute(
      `SELECT id, name, address, latitude, longitude, status, work_count, is_locked, locked_by, locked_at, updated_at
       FROM devices
       WHERE id = ?
       LIMIT 1`,
      [deviceId]
    );
    return rows[0] ? mapDeviceRow(rows[0]) : null;
  }

  async updateLockStatus(deviceId, isLocked, operator) {
    const lockedAt = isLocked ? Date.now() : 0;
    const updatedAt = Date.now();
    const lockedBy = isLocked ? operator : "";

    const [result] = await this.pool.execute(
      `UPDATE devices
       SET is_locked = ?,
           locked_by = ?,
           locked_at = ?,
           updated_at = ?
       WHERE id = ?`,
      [isLocked ? 1 : 0, lockedBy, lockedAt, updatedAt, deviceId]
    );

    if (result.affectedRows === 0) {
      return null;
    }

    return this.getDeviceById(deviceId);
  }

  async close() {
    await this.pool.end();
  }
}
