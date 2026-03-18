import test from "node:test";
import assert from "node:assert/strict";
import { createApp } from "../src/app.js";

function createRepositoryStub() {
  const devices = [
    {
      id: "DEV001",
      name: "数控机床-A01",
      address: "山东省枣庄市滕州市界河镇西万院村766号滕州市金果果蔬有限公司",
      latitude: 35.0827,
      longitude: 117.1536,
      status: 1,
      workCount: 1523,
      isLocked: false,
      lockedBy: "",
      lockedAt: 0,
      updatedAt: 1700000000000
    },
    {
      id: "DEV003",
      name: "冲压机-C03",
      address: "山东省济宁市邹城市钢山街道工业北路158号鑫泰重工集团",
      latitude: 35.4053,
      longitude: 117.0073,
      status: 0,
      workCount: 2341,
      isLocked: true,
      lockedBy: "admin",
      lockedAt: 1699913600000,
      updatedAt: 1700000000000
    }
  ];

  return {
    async validateUser(username, password) {
      if (username === "admin" && password === "admin123") {
        return { id: "USR001", username: "admin", role: "admin" };
      }
      if (username === "operator" && password === "operator123") {
        return { id: "USR002", username: "operator", role: "user" };
      }
      return null;
    },
    async getAllDevices() {
      return devices;
    },
    async getDeviceById(deviceId) {
      return devices.find((device) => device.id === deviceId) ?? null;
    },
    async updateLockStatus(deviceId, isLocked, operator) {
      const device = devices.find((item) => item.id === deviceId);
      if (!device) {
        return null;
      }

      device.isLocked = isLocked;
      device.lockedBy = isLocked ? operator : "";
      device.lockedAt = isLocked ? 1700100000000 : 0;
      device.updatedAt = 1700100000000;
      return device;
    },
    async createDevice(deviceId, address) {
      if (devices.some((item) => item.id === deviceId)) {
        const error = new Error("设备编号已存在");
        error.code = "DEVICE_EXISTS";
        throw error;
      }

      const device = {
        id: deviceId,
        name: deviceId,
        address,
        latitude: 0,
        longitude: 0,
        status: 2,
        workCount: 0,
        isLocked: false,
        lockedBy: "",
        lockedAt: 0,
        updatedAt: 1700200000000
      };
      devices.push(device);
      return device;
    }
  };
}

async function requestJson(server, path, options = {}) {
  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  const response = await fetch(`${baseUrl}${path}`, options);
  return {
    status: response.status,
    body: await response.json()
  };
}

test("POST /api/auth/login returns user profile for valid credentials", async () => {
  const app = createApp({ repository: createRepositoryStub() });
  const server = app.listen(0);

  try {
    const response = await requestJson(server, "/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: "admin123" })
    });

    assert.equal(response.status, 200);
    assert.equal(response.body.id, "USR001");
    assert.equal(response.body.username, "admin");
    assert.equal(response.body.role, "admin");
    assert.equal(typeof response.body.token, "string");
    assert.notEqual(response.body.token.length, 0);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("POST /api/auth/login rejects invalid credentials", async () => {
  const app = createApp({ repository: createRepositoryStub() });
  const server = app.listen(0);

  try {
    const response = await requestJson(server, "/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: "wrong" })
    });

    assert.equal(response.status, 401);
    assert.deepEqual(response.body, { message: "用户名或密码错误" });
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("GET /api/devices returns all devices", async () => {
  const app = createApp({ repository: createRepositoryStub() });
  const server = app.listen(0);

  try {
    const response = await requestJson(server, "/api/devices");

    assert.equal(response.status, 200);
    assert.equal(response.body.length, 2);
    assert.equal(response.body[0].id, "DEV001");
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("GET /api/devices/:id returns device detail", async () => {
  const app = createApp({ repository: createRepositoryStub() });
  const server = app.listen(0);

  try {
    const response = await requestJson(server, "/api/devices/DEV003");

    assert.equal(response.status, 200);
    assert.equal(response.body.id, "DEV003");
    assert.equal(response.body.isLocked, true);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("PUT /api/devices/:id/lock updates lock state", async () => {
  const app = createApp({ repository: createRepositoryStub() });
  const server = app.listen(0);

  try {
    const login = await requestJson(server, "/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: "admin123" })
    });

    const response = await requestJson(server, "/api/devices/DEV001/lock", {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${login.body.token}`
      },
      body: JSON.stringify({ isLocked: true, operator: "admin" })
    });

    assert.equal(response.status, 200);
    assert.equal(response.body.isLocked, true);
    assert.equal(response.body.lockedBy, "admin");
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("POST /api/devices creates a new device for admin token", async () => {
  const app = createApp({ repository: createRepositoryStub() });
  const server = app.listen(0);

  try {
    const login = await requestJson(server, "/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: "admin123" })
    });

    const response = await requestJson(server, "/api/devices", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${login.body.token}`
      },
      body: JSON.stringify({ id: "DEV006", address: "山东省新增地址" })
    });

    assert.equal(response.status, 201);
    assert.equal(response.body.id, "DEV006");
    assert.equal(response.body.name, "DEV006");
    assert.equal(response.body.status, 2);
    assert.equal(response.body.isLocked, false);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("POST /api/devices rejects requests without token", async () => {
  const app = createApp({ repository: createRepositoryStub() });
  const server = app.listen(0);

  try {
    const response = await requestJson(server, "/api/devices", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: "DEV006", address: "山东省新增地址" })
    });

    assert.equal(response.status, 401);
    assert.deepEqual(response.body, { message: "请先登录" });
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("POST /api/devices rejects non-admin tokens", async () => {
  const app = createApp({ repository: createRepositoryStub() });
  const server = app.listen(0);

  try {
    const login = await requestJson(server, "/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "operator", password: "operator123" })
    });

    const response = await requestJson(server, "/api/devices", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${login.body.token}`
      },
      body: JSON.stringify({ id: "DEV006", address: "山东省新增地址" })
    });

    assert.equal(response.status, 403);
    assert.deepEqual(response.body, { message: "仅管理员可执行此操作" });
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("POST /api/devices rejects duplicate device id", async () => {
  const app = createApp({ repository: createRepositoryStub() });
  const server = app.listen(0);

  try {
    const login = await requestJson(server, "/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: "admin123" })
    });

    const response = await requestJson(server, "/api/devices", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${login.body.token}`
      },
      body: JSON.stringify({ id: "DEV001", address: "山东省重复地址" })
    });

    assert.equal(response.status, 409);
    assert.deepEqual(response.body, { message: "设备编号已存在" });
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("PUT /api/devices/:id/lock rejects requests without token", async () => {
  const app = createApp({ repository: createRepositoryStub() });
  const server = app.listen(0);

  try {
    const response = await requestJson(server, "/api/devices/DEV001/lock", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isLocked: true, operator: "admin" })
    });

    assert.equal(response.status, 401);
    assert.deepEqual(response.body, { message: "请先登录" });
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

