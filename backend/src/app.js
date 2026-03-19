import express from "express";
import { InMemorySessionStore } from "./sessionStore.js";

function normalizeBoolean(value) {
  if (typeof value === "boolean") {
    return value;
  }
  if (value === "true" || value === "1" || value === 1) {
    return true;
  }
  if (value === "false" || value === "0" || value === 0) {
    return false;
  }
  return null;
}

function readBearerToken(headerValue) {
  if (typeof headerValue !== "string") {
    return "";
  }

  const match = headerValue.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : "";
}

function normalizeRole(value) {
  if (typeof value !== "string") {
    return "";
  }

  const normalized = value.trim().toLowerCase();
  return normalized === "admin" || normalized === "user" ? normalized : "";
}

export function createApp({ repository, sessionStore = new InMemorySessionStore() }) {
  if (!repository) {
    throw new Error("repository is required");
  }

  const app = express();
  app.use(express.json());

  app.use((req, _res, next) => {
    const token = readBearerToken(req.headers.authorization);
    req.auth = token ? sessionStore.getSession(token) : null;
    next();
  });

  const requireAuth = (req, res) => {
    if (!req.auth) {
      res.status(401).json({ message: "请先登录" });
      return false;
    }

    return true;
  };

  const requireAdmin = (req, res) => {
    if (!requireAuth(req, res)) {
      return false;
    }

    if (req.auth.role !== "admin") {
      res.status(403).json({ message: "仅管理员可执行此操作" });
      return false;
    }

    return true;
  };

  app.post("/api/auth/login", async (req, res, next) => {
    try {
      const { username, password } = req.body ?? {};
      if (!username || !password) {
        return res.status(400).json({ message: "用户名和密码不能为空" });
      }

      const user = await repository.validateUser(username, password);
      if (!user) {
        return res.status(401).json({ message: "用户名或密码错误" });
      }

      const session = sessionStore.createSession(user);
      return res.json({
        ...user,
        token: session.token
      });
    } catch (error) {
      return next(error);
    }
  });

  app.get("/api/devices", async (_req, res, next) => {
    try {
      const devices = await repository.getAllDevices();
      return res.json(devices);
    } catch (error) {
      return next(error);
    }
  });

  app.get("/api/devices/:id", async (req, res, next) => {
    try {
      const device = await repository.getDeviceById(req.params.id);
      if (!device) {
        return res.status(404).json({ message: "设备不存在" });
      }

      return res.json(device);
    } catch (error) {
      return next(error);
    }
  });

  app.post("/api/devices", async (req, res, next) => {
    try {
      if (!requireAdmin(req, res)) {
        return;
      }

      const { id, address } = req.body ?? {};
      const deviceId = typeof id === "string" ? id.trim() : "";
      const deviceAddress = typeof address === "string" ? address.trim() : "";

      if (!deviceId || !deviceAddress) {
        return res.status(400).json({ message: "设备编号和位置不能为空" });
      }

      const device = await repository.createDevice(deviceId, deviceAddress);
      return res.status(201).json(device);
    } catch (error) {
      if (error?.code === "DEVICE_EXISTS") {
        return res.status(409).json({ message: "设备编号已存在" });
      }
      return next(error);
    }
  });

  app.post("/api/users", async (req, res, next) => {
    try {
      if (!requireAdmin(req, res)) {
        return;
      }

      const rawUsername = typeof req.body?.username === "string" ? req.body.username.trim() : "";
      const rawPassword = typeof req.body?.password === "string" ? req.body.password : "";
      const role = normalizeRole(req.body?.role);

      if (!rawUsername || /\s/.test(rawUsername) || rawUsername.length > 32) {
        return res.status(400).json({ message: "用户名格式不正确" });
      }

      if (rawPassword.length < 6 || rawPassword.length > 32) {
        return res.status(400).json({ message: "密码长度需为 6-32 位" });
      }

      if (!role) {
        return res.status(400).json({ message: "用户角色无效" });
      }

      const user = await repository.createUser(rawUsername, rawPassword, role);
      return res.status(201).json(user);
    } catch (error) {
      if (error?.code === "USER_EXISTS") {
        return res.status(409).json({ message: "用户名已存在" });
      }
      return next(error);
    }
  });

  const lockHandler = async (req, res, next) => {
    try {
      if (!requireAdmin(req, res)) {
        return;
      }

      const { isLocked, operator } = req.body ?? {};
      const normalizedLockState = normalizeBoolean(isLocked);
      const effectiveOperator = req.auth?.username ?? operator;

      if (normalizedLockState === null || !effectiveOperator) {
        return res.status(400).json({ message: "请求参数无效" });
      }

      const device = await repository.updateLockStatus(req.params.id, normalizedLockState, effectiveOperator);
      if (!device) {
        return res.status(404).json({ message: "设备不存在" });
      }

      return res.json(device);
    } catch (error) {
      return next(error);
    }
  };

  app.patch("/api/devices/:id/lock", lockHandler);
  app.put("/api/devices/:id/lock", lockHandler);

  app.use((error, _req, res, _next) => {
    console.error("[backend] request failed", error);
    res.status(500).json({ message: "服务器内部错误" });
  });

  return app;
}

