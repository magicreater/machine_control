import fs from "node:fs/promises";
import path from "node:path";
import dotenv from "dotenv";
import mysql from "mysql2/promise";

dotenv.config({ path: path.resolve(process.cwd(), ".env") });

const config = {
  host: process.env.MYSQL_HOST ?? "127.0.0.1",
  port: Number(process.env.MYSQL_PORT ?? 3306),
  database: process.env.MYSQL_DATABASE ?? "platform",
  user: process.env.MYSQL_USER ?? "platform",
  password: process.env.MYSQL_PASSWORD ?? "change_me"
};

const sqlPath = path.resolve(process.cwd(), "scripts", "prepare-platform-db.sql");
const sql = await fs.readFile(sqlPath, "utf8");

const connection = await mysql.createConnection({
  ...config,
  multipleStatements: true
});

try {
  console.log(`[db] applying migration script: ${sqlPath}`);
  console.log(`[db] target: ${config.user}@${config.host}:${config.port}/${config.database}`);
  await connection.query(sql);
  console.log("[db] migration completed");
} finally {
  await connection.end();
}
