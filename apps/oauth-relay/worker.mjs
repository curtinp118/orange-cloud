const APP_CALLBACK = "curtinp118orangecloud://oauth/callback";

export default {
  async fetch(request) {
    const headers = {
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
    };
    if (request.method !== "GET") {
      return new Response("Method not allowed", {
        status: 405,
        headers: { ...headers, Allow: "GET" },
      });
    }
    const url = new URL(request.url);
    if (url.pathname === "/health") {
      return Response.json({ ok: true }, { headers });
    }
    if (url.pathname !== "/oauth/callback") {
      return new Response("Personal Cloudflare OAuth callback relay.", {
        status: url.pathname === "/" ? 200 : 404,
        headers: { ...headers, "Content-Type": "text/plain; charset=utf-8" },
      });
    }

    const callback = new URL(APP_CALLBACK);
    const error = url.searchParams.get("error");
    if (error) {
      callback.searchParams.set(
        "error",
        url.searchParams.get("error_description") || error,
      );
    } else {
      const code = url.searchParams.get("code");
      const state = url.searchParams.get("state");
      if (!code || !state) {
        callback.searchParams.set("error", "invalid_response");
      } else {
        callback.searchParams.set("code", code);
        callback.searchParams.set("state", state);
      }
    }
    return new Response(null, {
      status: 302,
      headers: { ...headers, Location: callback.toString() },
    });
  },
};
