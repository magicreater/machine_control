import { createApp } from "./app.js";
import { getConfig } from "./config.js";
import { MysqlRepository } from "./repository/mysqlRepository.js";

const config = getConfig();
const repository = new MysqlRepository(config);
const app = createApp({ repository });

const server = app.listen(config.apiPort, () => {
  console.log(`Machine Control backend listening on port ${config.apiPort}`);
});

async function shutdown() {
  server.close(async () => {
    await repository.close();
    process.exit(0);
  });
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
