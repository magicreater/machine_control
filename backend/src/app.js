import express from "express";

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

export function createApp({ repository }) {
  if (!repository) {
    throw new Error("repository is required");
  }

  const app = express();
  app.use(express.json());

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

      return res.json(user);
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

  const lockHandler = async (req, res, next) => {
    try {
      const { isLocked, operator } = req.body ?? {};
      const normalizedLockState = normalizeBoolean(isLocked);

      if (normalizedLockState === null || !operator) {
        return res.status(400).json({ message: "请求参数无效" });
      }

      const device = await repository.updateLockStatus(req.params.id, normalizedLockState, operator);
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

