import { createApp } from "./app.js";
import { getConfig } from "./config.js";
import { MysqlRepository } from "./repository/mysqlRepository.js";

export async function initializeRuntime(options = {}) {
  const config = options.config ?? getConfig();
  const repository = options.repository ?? new MysqlRepository(config);
  const logger = options.logger ?? console;

  await repository.verifySchema();
  logger.info?.(`[backend] verified schema for database ${config.mysqlDatabase ?? "unknown"}`);

  return {
    app: createApp({ repository }),
    config,
    repository
  };
}
