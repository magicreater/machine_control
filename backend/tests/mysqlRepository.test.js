import test from "node:test";
import assert from "node:assert/strict";
import {
  MysqlRepository,
  mapDetailRow,
  mapDetailStatus,
  normalizeRole
} from "../src/repository/mysqlRepository.js";

class FakePool {
  constructor(responses = []) {
    this.responses = responses;
    this.calls = [];
  }

  async execute(sql, params = []) {
    this.calls.push({ sql, params });
    if (this.responses.length === 0) {
      throw new Error("Unexpected execute call");
    }

    const next = this.responses.shift();
    if (next instanceof Error) {
      throw next;
    }
    return next;
  }

  async end() {
    return undefined;
  }
}

function createRepositoryWithResponses(responses) {
  const pool = new FakePool(responses);
  const repository = new MysqlRepository(
    {
      mysqlHost: "127.0.0.1",
      mysqlPort: 3306,
      mysqlDatabase: "platform",
      mysqlUser: "platform",
      mysqlPassword: "123456"
    },
    { pool }
  );

  return { repository, pool };
}

test("normalizeRole returns admin for admin table records", () => {
  assert.equal(normalizeRole("ADMIN"), "admin");
  assert.equal(normalizeRole("manager", "admin"), "admin");
});

test("mapDetailStatus converts known platform statuses", () => {
  assert.equal(mapDetailStatus("run"), 1);
  assert.equal(mapDetailStatus("working"), 1);
  assert.equal(mapDetailStatus("standby"), 2);
  assert.equal(mapDetailStatus("idle"), 2);
  assert.equal(mapDetailStatus("stop"), 0);
  assert.equal(mapDetailStatus("unknown"), 0);
});

test("mapDetailRow maps details table fields into device dto", () => {
  const mapped = mapDetailRow({
    equipmentId: "DEV001",
    location: "山东省测试地址",
    latitude: "35.0827",
    longitude: "117.1536",
    status: "run",
    total: 1523,
    isLocked: 1,
    lck: "1",
    lockedBy: "admin",
    lockedAt: 1700000000000,
    updatedAt: 1700000005000
  });

  assert.deepEqual(mapped, {
    id: "DEV001",
    name: "DEV001",
    address: "山东省测试地址",
    latitude: 35.0827,
    longitude: 117.1536,
    status: 1,
    workCount: 1523,
    isLocked: true,
    lockedBy: "admin",
    lockedAt: 1700000000000,
    updatedAt: 1700000005000
  });
});

test("validateUser prefers admin table and normalizes role", async () => {
  const { repository, pool } = createRepositoryWithResponses([
    [[{ id: 1, username: "admin", role: "ADMIN" }]],
    [[{ id: 42, username: "admin", role: "USER" }]]
  ]);

  const user = await repository.validateUser("admin", "admin");

  assert.deepEqual(user, {
    id: "1",
    username: "admin",
    role: "admin"
  });
  assert.equal(pool.calls.length, 1);
  assert.match(pool.calls[0].sql, /FROM\s+`?admin`?/i);
});

test("validateUser falls back to user table when admin misses", async () => {
  const { repository, pool } = createRepositoryWithResponses([
    [[]],
    [[{ id: 42, username: "operator", role: "USER" }]]
  ]);

  const user = await repository.validateUser("operator", "123");

  assert.deepEqual(user, {
    id: "42",
    username: "operator",
    role: "user"
  });
  assert.equal(pool.calls.length, 2);
  assert.match(pool.calls[0].sql, /FROM\s+`?admin`?/i);
  assert.match(pool.calls[1].sql, /FROM\s+`?user`?/i);
});

test("getAllDevices reads platform details rows ordered by equipmentId", async () => {
  const { repository, pool } = createRepositoryWithResponses([
    [[
      {
        equipmentId: "DEV002",
        location: "B",
        latitude: 35.1,
        longitude: 117.1,
        status: "standby",
        total: 20,
        isLocked: 0,
        lck: "0",
        lockedBy: null,
        lockedAt: null,
        updatedAt: 1000
      }
    ]]
  ]);

  const devices = await repository.getAllDevices();

  assert.equal(devices.length, 1);
  assert.equal(devices[0].id, "DEV002");
  assert.match(pool.calls[0].sql, /FROM details/i);
  assert.match(pool.calls[0].sql, /ORDER BY equipmentId ASC/i);
});

test("updateLockStatus writes both new and legacy lock fields", async () => {
  const { repository, pool } = createRepositoryWithResponses([
    [{ affectedRows: 1 }],
    [[
      {
        equipmentId: "DEV001",
        location: "A",
        latitude: 35.0,
        longitude: 117.0,
        status: "run",
        total: 99,
        isLocked: 1,
        lck: "1",
        lockedBy: "admin",
        lockedAt: 1700000000000,
        updatedAt: 1700000000000
      }
    ]]
  ]);

  const device = await repository.updateLockStatus("DEV001", true, "admin");

  assert.equal(device?.isLocked, true);
  assert.match(pool.calls[0].sql, /UPDATE details/i);
  assert.match(pool.calls[0].sql, /isLocked = \?/i);
  assert.match(pool.calls[0].sql, /lck = \?/i);
  assert.match(pool.calls[0].sql, /lockedBy = \?/i);
  assert.match(pool.calls[0].sql, /lockedAt = \?/i);
  assert.match(pool.calls[0].sql, /updatedAt = \?/i);
  assert.match(pool.calls[0].sql, /lastUpdate = FROM_UNIXTIME/i);
});

test("createDevice inserts default values for a new details row", async () => {
  const { repository, pool } = createRepositoryWithResponses([
    [{ affectedRows: 1 }],
    [[
      {
        equipmentId: "DEV006",
        location: "山东省新增地址",
        latitude: 0,
        longitude: 0,
        status: "standby",
        total: 0,
        isLocked: 0,
        lck: "0",
        lockedBy: "",
        lockedAt: 0,
        updatedAt: 1700000000000
      }
    ]]
  ]);

  const device = await repository.createDevice("DEV006", "山东省新增地址");

  assert.equal(device?.id, "DEV006");
  assert.equal(device?.name, "DEV006");
  assert.equal(device?.status, 2);
  assert.equal(device?.workCount, 0);
  assert.match(pool.calls[0].sql, /INSERT INTO details/i);
  assert.deepEqual(pool.calls[0].params.slice(0, 10), [
    "DEV006",
    "山东省新增地址",
    0,
    0,
    "standby",
    0,
    0,
    "0",
    "",
    0
  ]);
});

test("createDevice surfaces duplicate device ids as DEVICE_EXISTS", async () => {
  const duplicate = new Error("Duplicate entry");
  duplicate.code = "ER_DUP_ENTRY";
  const { repository } = createRepositoryWithResponses([duplicate]);

  await assert.rejects(
    repository.createDevice("DEV001", "山东省重复地址"),
    (error) => error.code === "DEVICE_EXISTS" && /设备编号已存在/i.test(error.message)
  );
});

test("verifySchema throws a readable error when details columns are missing", async () => {
  const { repository } = createRepositoryWithResponses([
    [[
      { TABLE_NAME: "admin", COLUMN_NAME: "id" },
      { TABLE_NAME: "admin", COLUMN_NAME: "username" },
      { TABLE_NAME: "admin", COLUMN_NAME: "password" },
      { TABLE_NAME: "user", COLUMN_NAME: "id" },
      { TABLE_NAME: "user", COLUMN_NAME: "username" },
      { TABLE_NAME: "user", COLUMN_NAME: "password" },
      { TABLE_NAME: "details", COLUMN_NAME: "equipmentId" },
      { TABLE_NAME: "details", COLUMN_NAME: "location" }
    ]],
    [[{ TABLE_NAME: "details", INDEX_NAME: "idx_device", COLUMN_NAME: "equipmentId", NON_UNIQUE: 1 }]]
  ]);

  await assert.rejects(
    repository.verifySchema(),
    /details missing columns: latitude, longitude, status, total, isLocked, lck, lockedBy, lockedAt, updatedAt, lastUpdate/i
  );
});

test("verifySchema passes when required tables, columns, and unique index exist", async () => {
  const { repository } = createRepositoryWithResponses([
    [[
      { TABLE_NAME: "admin", COLUMN_NAME: "id" },
      { TABLE_NAME: "admin", COLUMN_NAME: "username" },
      { TABLE_NAME: "admin", COLUMN_NAME: "password" },
      { TABLE_NAME: "user", COLUMN_NAME: "id" },
      { TABLE_NAME: "user", COLUMN_NAME: "username" },
      { TABLE_NAME: "user", COLUMN_NAME: "password" },
      { TABLE_NAME: "details", COLUMN_NAME: "equipmentId" },
      { TABLE_NAME: "details", COLUMN_NAME: "location" },
      { TABLE_NAME: "details", COLUMN_NAME: "latitude" },
      { TABLE_NAME: "details", COLUMN_NAME: "longitude" },
      { TABLE_NAME: "details", COLUMN_NAME: "status" },
      { TABLE_NAME: "details", COLUMN_NAME: "total" },
      { TABLE_NAME: "details", COLUMN_NAME: "isLocked" },
      { TABLE_NAME: "details", COLUMN_NAME: "lck" },
      { TABLE_NAME: "details", COLUMN_NAME: "lockedBy" },
      { TABLE_NAME: "details", COLUMN_NAME: "lockedAt" },
      { TABLE_NAME: "details", COLUMN_NAME: "updatedAt" },
      { TABLE_NAME: "details", COLUMN_NAME: "lastUpdate" }
    ]],
    [[{ TABLE_NAME: "details", INDEX_NAME: "uq_details_equipmentId", COLUMN_NAME: "equipmentId", NON_UNIQUE: 0 }]]
  ]);

  await assert.doesNotReject(repository.verifySchema());
});
