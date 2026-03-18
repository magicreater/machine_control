import mysql from "mysql2/promise";

const STATUS_TO_DEVICE_STATUS = new Map([
  ["run", 1],
  ["working", 1],
  ["standby", 2],
  ["idle", 2],
  ["stop", 0]
]);

const REQUIRED_SCHEMA = {
  admin: ["id", "username", "password"],
  user: ["id", "username", "password"],
  details: [
    "equipmentId",
    "location",
    "latitude",
    "longitude",
    "status",
    "total",
    "isLocked",
    "lck",
    "lockedBy",
    "lockedAt",
    "updatedAt",
    "lastUpdate"
  ]
};

function toNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function toTrimmedLowerCase(value) {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function parseTimestamp(value) {
  if (value === null || value === undefined || value === "") {
    return 0;
  }

  if (typeof value === "number") {
    return Number.isFinite(value) ? value : 0;
  }

  const numeric = Number(value);
  if (Number.isFinite(numeric) && `${numeric}` === `${value}`) {
    return numeric;
  }

  const parsed = Date.parse(String(value).replace(" ", "T"));
  return Number.isFinite(parsed) ? parsed : 0;
}

function parseLockState(isLocked, legacyLockValue) {
  if (typeof isLocked === "boolean") {
    return isLocked;
  }

  if (isLocked === 1 || isLocked === "1") {
    return true;
  }

  if (isLocked === 0 || isLocked === "0") {
    return false;
  }

  const normalizedLegacy = toTrimmedLowerCase(legacyLockValue);
  return ["1", "true", "locked", "yes", "y"].includes(normalizedLegacy);
}

export function normalizeRole(role, source = "user") {
  if (source === "admin") {
    return "admin";
  }

  return toTrimmedLowerCase(role) === "admin" ? "admin" : "user";
}

export function mapDetailStatus(status) {
  return STATUS_TO_DEVICE_STATUS.get(toTrimmedLowerCase(status)) ?? 0;
}

export function mapDetailRow(row) {
  return {
    id: String(row.equipmentId),
    name: String(row.equipmentId),
    address: row.location ?? "",
    latitude: toNumber(row.latitude),
    longitude: toNumber(row.longitude),
    status: mapDetailStatus(row.status),
    workCount: toNumber(row.total),
    isLocked: parseLockState(row.isLocked, row.lck),
    lockedBy: row.lockedBy ?? "",
    lockedAt: parseTimestamp(row.lockedAt),
    updatedAt: parseTimestamp(row.updatedAt ?? row.lastUpdate)
  };
}

async function queryUserFromTable(pool, tableName, username, password) {
  const [rows] = await pool.execute(
    `SELECT id, username, role
     FROM \`${tableName}\`
     WHERE username = ? AND password = ?
     LIMIT 1`,
    [username, password]
  );

  return rows[0] ?? null;
}

export class MysqlRepository {
  constructor(config, options = {}) {
    this.databaseName = config.mysqlDatabase;
    this.pool = options.pool ?? mysql.createPool({
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
    const admin = await queryUserFromTable(this.pool, "admin", username, password);
    if (admin) {
      return {
        id: String(admin.id),
        username: admin.username,
        role: normalizeRole(admin.role, "admin")
      };
    }

    const user = await queryUserFromTable(this.pool, "user", username, password);
    return user
      ? {
          id: String(user.id),
          username: user.username,
          role: normalizeRole(user.role, "user")
        }
      : null;
  }

  async verifySchema() {
    const [columns] = await this.pool.execute(
      `SELECT TABLE_NAME, COLUMN_NAME
       FROM information_schema.COLUMNS
       WHERE TABLE_SCHEMA = ?
         AND TABLE_NAME IN ('admin', 'user', 'details')`,
      [this.databaseName]
    );

    const [indexes] = await this.pool.execute(
      `SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME, NON_UNIQUE
       FROM information_schema.STATISTICS
       WHERE TABLE_SCHEMA = ?
         AND TABLE_NAME = 'details'`,
      [this.databaseName]
    );

    const columnsByTable = new Map();
    for (const row of columns) {
      const tableColumns = columnsByTable.get(row.TABLE_NAME) ?? new Set();
      tableColumns.add(row.COLUMN_NAME);
      columnsByTable.set(row.TABLE_NAME, tableColumns);
    }

    const problems = [];
    for (const [tableName, requiredColumns] of Object.entries(REQUIRED_SCHEMA)) {
      const availableColumns = columnsByTable.get(tableName) ?? new Set();
      const missingColumns = requiredColumns.filter((column) => !availableColumns.has(column));

      if (availableColumns.size === 0) {
        problems.push(`missing table: ${tableName}`);
        continue;
      }

      if (missingColumns.length > 0) {
        problems.push(`${tableName} missing columns: ${missingColumns.join(", ")}`);
      }
    }

    const hasUniqueEquipmentId = indexes.some((row) =>
      row.COLUMN_NAME === "equipmentId" && Number(row.NON_UNIQUE) === 0
    );
    if (!hasUniqueEquipmentId) {
      problems.push("details missing unique index on equipmentId");
    }

    if (problems.length > 0) {
      throw new Error(`platform schema mismatch: ${problems.join("; ")}`);
    }
  }

  async getAllDevices() {
    const [rows] = await this.pool.execute(
      `SELECT equipmentId, location, latitude, longitude, status, total, isLocked, lck, lockedBy, lockedAt, updatedAt, lastUpdate
       FROM details
       ORDER BY equipmentId ASC`
    );
    return rows.map(mapDetailRow);
  }

  async getDeviceById(deviceId) {
    const [rows] = await this.pool.execute(
      `SELECT equipmentId, location, latitude, longitude, status, total, isLocked, lck, lockedBy, lockedAt, updatedAt, lastUpdate
       FROM details
       WHERE equipmentId = ?
       LIMIT 1`,
      [deviceId]
    );

    return rows[0] ? mapDetailRow(rows[0]) : null;
  }

  async updateLockStatus(deviceId, isLocked, operator) {
    const lockedAt = isLocked ? Date.now() : 0;
    const updatedAt = Date.now();
    const lockedBy = isLocked ? operator : "";
    const legacyLockValue = isLocked ? "1" : "0";

    const [result] = await this.pool.execute(
      `UPDATE details
       SET isLocked = ?,
           lck = ?,
           lockedBy = ?,
           lockedAt = ?,
           updatedAt = ?,
           lastUpdate = FROM_UNIXTIME(? / 1000)
       WHERE equipmentId = ?`,
      [isLocked ? 1 : 0, legacyLockValue, lockedBy, lockedAt, updatedAt, updatedAt, deviceId]
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
