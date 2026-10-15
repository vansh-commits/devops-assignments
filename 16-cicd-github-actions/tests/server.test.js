const test = require("node:test");
const assert = require("node:assert");
const http = require("node:http");
const { greeting, handler } = require("../app/server");

test("greeting says Hello World by default", () => {
  assert.strictEqual(greeting(), "Hello World from Vansh's CI/CD demo app!");
});

test("greeting uses the given name", () => {
  assert.strictEqual(greeting("DevOps"), "Hello DevOps from Vansh's CI/CD demo app!");
});

test("/health returns ok", async () => {
  const server = http.createServer(handler).listen(0);
  const { port } = server.address();
  const res = await fetch(`http://localhost:${port}/health`);
  assert.strictEqual(res.status, 200);
  assert.deepStrictEqual(await res.json(), { status: "ok" });
  server.close();
});
