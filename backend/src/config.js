import dotenv from "dotenv";

dotenv.config();

function readRequiredEnv(name, fallback = "") {
  const value = process.env[name] ?? fallback;
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function getConfig() {
  return {
    apiPort: Number(process.env.API_PORT ?? 3000),
    mysqlHost: readRequiredEnv("MYSQL_HOST", "127.0.0.1"),
    mysqlPort: Number(process.env.MYSQL_PORT ?? 3306),
    mysqlDatabase: readRequiredEnv("MYSQL_DATABASE", "machine_control"),
    mysqlUser: readRequiredEnv("MYSQL_USER", "machine_control_app"),
    mysqlPassword: readRequiredEnv("MYSQL_PASSWORD", "change_me")
  };
}
