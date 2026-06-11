import { cors } from "../_shared/cors.ts";

const HADITH_KEY = Deno.env.get("HADITH_API_KEY")!;
const BASE = "https://api.sunnah.com/v1";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { path, query } = await req.json();

    // Safelist: only sunnah.com collection endpoints may be proxied, so this
    // can't be used as an open proxy to arbitrary sunnah.com paths.
    if (typeof path !== "string" || !path.startsWith("/collections")) {
      return new Response(
        JSON.stringify({ error: "invalid path" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const qs = query && typeof query === "object"
      ? "?" +
        new URLSearchParams(
          Object.entries(query).map(([k, v]) => [k, String(v)]),
        ).toString()
      : "";

    const r = await fetch(`${BASE}${path}${qs}`, {
      headers: { "X-API-Key": HADITH_KEY },
    });
    const data = await r.text(); // pass through verbatim
    return new Response(data, {
      status: r.status,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
