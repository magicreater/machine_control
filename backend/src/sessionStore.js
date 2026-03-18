import crypto from "node:crypto";

const SESSION_TTL_MS = 8 * 60 * 60 * 1000;

function cloneSession(session) {
  return {
    token: session.token,
    userId: session.userId,
    username: session.username,
    role: session.role,
    expiresAt: session.expiresAt
  };
}

export class InMemorySessionStore {
  constructor(options = {}) {
    this.ttlMs = options.ttlMs ?? SESSION_TTL_MS;
    this.now = options.now ?? (() => Date.now());
    this.sessions = new Map();
  }

  createSession(user) {
    const token = crypto.randomBytes(24).toString("hex");
    const session = {
      token,
      userId: String(user.id),
      username: user.username,
      role: user.role,
      expiresAt: this.now() + this.ttlMs
    };

    this.sessions.set(token, session);
    return cloneSession(session);
  }

  getSession(token) {
    if (!token) {
      return null;
    }

    const session = this.sessions.get(token);
    if (!session) {
      return null;
    }

    if (session.expiresAt <= this.now()) {
      this.sessions.delete(token);
      return null;
    }

    return cloneSession(session);
  }

  clear() {
    this.sessions.clear();
  }
}

export { SESSION_TTL_MS };
