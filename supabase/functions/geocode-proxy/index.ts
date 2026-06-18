import { cors } from "../_shared/cors.ts";
import { isRateLimited } from "../_shared/rate_limit.ts";

const MAPS_KEY = Deno.env.get("GOOGLE_MAPS_API_KEY")!;
const BASE = "https://maps.googleapis.com/maps/api/geocode/json";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    if (await isRateLimited(req, "geocode")) {
      return new Response(
        JSON.stringify({ error: { message: "rate limited" } }),
        { status: 429, headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const { lat, lon, address } = await req.json();
    const url = address != null
      ? `${BASE}?address=${encodeURIComponent(address)}&key=${MAPS_KEY}`
      : `${BASE}?latlng=${lat},${lon}&key=${MAPS_KEY}`;

    const r = await fetch(url);
    const data = await r.text(); // pass through verbatim
    return new Response(data, {
      status: r.status,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ status: "ERROR", error_message: String(e) }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
