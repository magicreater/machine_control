import test from "node:test";
import assert from "node:assert/strict";
import { getConfig } from "../src/config.js";

test("getConfig exposes api host with a safe default", () => {
  const previous = process.env.API_HOST;

  try {
    delete process.env.API_HOST;
    assert.equal(getConfig().apiHost, "0.0.0.0");

    process.env.API_HOST = "127.0.0.1";
    assert.equal(getConfig().apiHost, "127.0.0.1");
  } finally {
    if (previous === undefined) {
      delete process.env.API_HOST;
    } else {
      process.env.API_HOST = previous;
    }
  }
});
