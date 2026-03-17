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
    assert.deepEqual(response.body, {
      id: "USR001",
      username: "admin",
      role: "admin"
    });
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
    const response = await requestJson(server, "/api/devices/DEV001/lock", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isLocked: true, operator: "admin" })
    });

    assert.equal(response.status, 200);
    assert.equal(response.body.isLocked, true);
    assert.equal(response.body.lockedBy, "admin");
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

