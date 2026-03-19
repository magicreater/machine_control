import mysql from "mysql2/promise";

const STATUS_TO_DEVICE_STATUS = new Map([
  ["run", 1],
  ["working", 1],
  ["standby", 2],
  ["idle", 2],
  ["stop", 0]
]);

const DETAIL_BASE_COLUMNS = [
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
];

const REQUIRED_SCHEMA = {
  admin: ["id", "username", "password"],
  user: ["id", "username", "password"],
  details: DETAIL_BASE_COLUMNS
};

const OPTIONAL_DETAIL_COLUMNS = [
  "model",
  "time",
  "bad",
  "rottencount",
  "greenSkin",
  "mechanicalDamage",
  "sprouted"
];

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

function buildUserId(role) {
  const prefix = role === "admin" ? "ADM" : "USR";
  const timestamp = Date.now().toString(36).toUpperCase();
  const suffix = Math.floor(Math.random() * 1000).toString().padStart(3, "0");
  return `${prefix}${timestamp}${suffix}`;
}

function getStoredRoleValue(role) {
  return role === "admin" ? "ADMIN" : "USER";
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
    badCount: toNumber(row.bad),
    rottenCount: toNumber(row.rottencount),
    greenSkinCount: toNumber(row.greenSkin),
    mechanicalDamageCount: toNumber(row.mechanicalDamage),
    sproutedCount: toNumber(row.sprouted),
    isLocked: parseLockState(row.isLocked, row.lck),
    lockedBy: row.lockedBy ?? "",
    lockedAt: parseTimestamp(row.lockedAt),
    updatedAt: parseTimestamp(row.updatedAt ?? row.lastUpdate)
  };
}

async function queryUserFromTable(pool, tableName, username, password, tableColumns = null) {
  const defaultRole = tableName === "admin" ? "admin" : "user";
  const hasRoleColumn = tableColumns?.has("role") ?? false;
  const roleSelect = hasRoleColumn ? "role" : "? AS role";
  const params = hasRoleColumn ? [username, password] : [defaultRole, username, password];

  const [rows] = await pool.execute(
    `SELECT id, username, ${roleSelect}
     FROM \`${tableName}\`
     WHERE username = ? AND password = ?
     LIMIT 1`,
    params
  );

  return rows[0] ?? null;
}

export class MysqlRepository {
  constructor(config, options = {}) {
    this.databaseName = config.mysqlDatabase;
    this.detailsColumns = null;
    this.userTableColumns = new Map();
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
    const admin = await queryUserFromTable(
      this.pool,
      "admin",
      username,
      password,
      this.userTableColumns.get("admin") ?? null
    );
    if (admin) {
      return {
        id: String(admin.id),
        username: admin.username,
        role: normalizeRole(admin.role, "admin")
      };
    }

    const user = await queryUserFromTable(
      this.pool,
      "user",
      username,
      password,
      this.userTableColumns.get("user") ?? null
    );
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

    this.userTableColumns = new Map([
      ["admin", columnsByTable.get("admin") ?? new Set()],
      ["user", columnsByTable.get("user") ?? new Set()]
    ]);
    this.detailsColumns = columnsByTable.get("details") ?? new Set();
  }

  async getAllDevices() {
    const [rows] = await this.pool.execute(
      `SELECT ${this.getSelectableDetailsColumns().join(", ")}
       FROM details
       ORDER BY equipmentId ASC`
    );
    return rows.map(mapDetailRow);
  }

  async getDeviceById(deviceId) {
    const [rows] = await this.pool.execute(
      `SELECT ${this.getSelectableDetailsColumns().join(", ")}
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

  async createDevice(deviceId, address) {
    const updatedAt = Date.now();
    const insertValues = {
      equipmentId: deviceId,
      model: deviceId,
      location: address,
      latitude: 0,
      longitude: 0,
      status: "standby",
      total: 0,
      isLocked: 0,
      lck: "0",
      lockedBy: "",
      lockedAt: 0,
      updatedAt,
      lastUpdate: updatedAt,
      time: 0,
      bad: 0,
      rottencount: 0,
      greenSkin: 0,
      mechanicalDamage: 0,
      sprouted: 0
    };

    const columns = this.getInsertableDetailsColumns();
    const params = [];
    const valueSql = columns.map((columnName) => {
      if (columnName === "lastUpdate") {
        params.push(insertValues[columnName]);
        return "FROM_UNIXTIME(? / 1000)";
      }

      params.push(insertValues[columnName]);
      return "?";
    });

    try {
      await this.pool.execute(
        `INSERT INTO details (${columns.join(", ")})
         VALUES (${valueSql.join(", ")})`,
        params
      );
    } catch (error) {
      if (error?.code === "ER_DUP_ENTRY") {
        const conflictError = new Error("设备编号已存在");
        conflictError.code = "DEVICE_EXISTS";
        throw conflictError;
      }

      throw error;
    }

    return this.getDeviceById(deviceId);
  }

  async createUser(username, password, role) {
    const normalizedRole = role === "admin" ? "admin" : role === "user" ? "user" : "";
    if (!normalizedRole) {
      const invalidRoleError = new Error("用户角色无效");
      invalidRoleError.code = "INVALID_ROLE";
      throw invalidRoleError;
    }

    await this.ensureSchemaMetadata();

    if (await this.usernameExists(username)) {
      const conflictError = new Error("用户名已存在");
      conflictError.code = "USER_EXISTS";
      throw conflictError;
    }

    const tableName = normalizedRole === "admin" ? "admin" : "user";
    const tableColumns = this.userTableColumns.get(tableName) ?? new Set();
    const id = buildUserId(normalizedRole);
    const createdAt = Date.now();
    const values = [];

    if (tableColumns.has("id")) values.push(["id", id]);
    if (tableColumns.has("username")) values.push(["username", username]);
    if (tableColumns.has("password")) values.push(["password", password]);
    if (tableColumns.has("role")) values.push(["role", getStoredRoleValue(normalizedRole)]);
    if (tableColumns.has("name")) values.push(["name", username]);
    if (tableColumns.has("phone")) values.push(["phone", null]);
    if (tableColumns.has("email")) values.push(["email", null]);
    if (tableColumns.has("avatar")) values.push(["avatar", null]);
    if (tableColumns.has("created_at")) values.push(["created_at", createdAt]);
    if (tableColumns.has("createdAt")) values.push(["createdAt", createdAt]);

    const columns = values.map(([columnName]) => `\`${columnName}\``);
    const params = values.map(([, value]) => value);

    try {
      await this.pool.execute(
        `INSERT INTO \`${tableName}\` (${columns.join(", ")})
         VALUES (${columns.map(() => "?").join(", ")})`,
        params
      );
    } catch (error) {
      if (error?.code === "ER_DUP_ENTRY") {
        const conflictError = new Error("用户名已存在");
        conflictError.code = "USER_EXISTS";
        throw conflictError;
      }

      throw error;
    }

    return {
      id,
      username,
      role: normalizedRole
    };
  }

  getSelectableDetailsColumns() {
    if (!this.detailsColumns) {
      return DETAIL_BASE_COLUMNS;
    }

    const optionalColumns = OPTIONAL_DETAIL_COLUMNS.filter((columnName) => this.detailsColumns.has(columnName));
    return [...DETAIL_BASE_COLUMNS, ...optionalColumns];
  }

  getInsertableDetailsColumns() {
    if (!this.detailsColumns) {
      return DETAIL_BASE_COLUMNS;
    }

    const optionalColumns = OPTIONAL_DETAIL_COLUMNS.filter((columnName) => this.detailsColumns.has(columnName));
    const availableBaseColumns = DETAIL_BASE_COLUMNS.filter((columnName) => this.detailsColumns.has(columnName));
    return ["equipmentId", ...optionalColumns, ...availableBaseColumns.filter((columnName) => columnName !== "equipmentId")];
  }

  async ensureSchemaMetadata() {
    if (this.detailsColumns && this.userTableColumns.get("admin") && this.userTableColumns.get("user")) {
      return;
    }

    await this.verifySchema();
  }

  async usernameExists(username) {
    for (const tableName of ["admin", "user"]) {
      const [rows] = await this.pool.execute(
        `SELECT 1
         FROM \`${tableName}\`
         WHERE username = ?
         LIMIT 1`,
        [username]
      );

      if (rows[0]) {
        return true;
      }
    }

    return false;
  }

  async close() {
    await this.pool.end();
  }
}
