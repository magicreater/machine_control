import { initializeRuntime } from "./bootstrap.js";

const { app, config, repository } = await initializeRuntime();

const server = app.listen(config.apiPort, config.apiHost, () => {
  console.log(`Machine Control backend listening on ${config.apiHost}:${config.apiPort}`);
});

async function shutdown() {
  server.close(async () => {
    await repository.close();
    process.exit(0);
  });
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
