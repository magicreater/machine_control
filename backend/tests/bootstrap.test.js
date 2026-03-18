import test from "node:test";
import assert from "node:assert/strict";
import { initializeRuntime } from "../src/bootstrap.js";

test("initializeRuntime verifies schema before returning the app", async () => {
  let verifySchemaCalled = false;
  const repository = {
    async verifySchema() {
      verifySchemaCalled = true;
    }
  };

  const runtime = await initializeRuntime({
    config: { apiPort: 3000 },
    repository,
    logger: { info() {} }
  });

  assert.equal(verifySchemaCalled, true);
  assert.equal(typeof runtime.app.use, "function");
  assert.equal(runtime.repository, repository);
  assert.equal(runtime.config.apiPort, 3000);
});
