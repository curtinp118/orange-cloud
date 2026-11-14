import assert from "node:assert/strict";
import test from "node:test";
import worker from "./worker.mjs";

const base = "https://personal.example/oauth/callback";

test("forwards code and state exactly to the fixed app callback", async () => {
  const url = new URL(base);
  url.searchParams.set("code", "test+code/=&");
  url.searchParams.set("state", "test state&value");
  url.searchParams.set("redirect_uri", "https://untrusted.example");
  const response = await worker.fetch(new Request(url));
  const destination = new URL(response.headers.get("Location"));
  assert.equal(response.status, 302);
  assert.equal(destination.protocol, "curtinp118orangecloud:");
  assert.equal(destination.hostname, "oauth");
  assert.equal(destination.pathname, "/callback");
  assert.equal(destination.searchParams.get("code"), "test+code/=&");
  assert.equal(destination.searchParams.get("state"), "test state&value");
  assert.equal(destination.searchParams.has("redirect_uri"), false);
  assert.equal(response.headers.get("Cache-Control"), "no-store");
  assert.equal(response.headers.get("Referrer-Policy"), "no-referrer");
});

test("rejects incomplete authorization responses", async () => {
  for (const query of ["", "?code=test", "?state=test"]) {
    const response = await worker.fetch(new Request(base + query));
    const destination = new URL(response.headers.get("Location"));
    assert.equal(destination.searchParams.get("error"), "invalid_response");
    assert.equal(destination.searchParams.has("code"), false);
  }
});

test("returns provider errors without treating them as successful grants", async () => {
  const url = new URL(base);
  url.searchParams.set("error", "access_denied");
  url.searchParams.set("error_description", "Test & cancellation");
  url.searchParams.set("code", "ignored");
  const response = await worker.fetch(new Request(url));
  const destination = new URL(response.headers.get("Location"));
  assert.equal(destination.searchParams.get("error"), "Test & cancellation");
  assert.equal(destination.searchParams.has("code"), false);
});

test("serves health checks and rejects other paths and methods", async () => {
  const health = await worker.fetch(new Request("https://personal.example/health"));
  assert.deepEqual(await health.json(), { ok: true });
  assert.equal(
    (await worker.fetch(new Request("https://personal.example/missing"))).status,
    404,
  );
  const post = await worker.fetch(new Request(base, { method: "POST" }));
  assert.equal(post.status, 405);
  assert.equal(post.headers.get("Allow"), "GET");
});
