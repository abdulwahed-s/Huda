import { cors } from "../_shared/cors.ts";
import { isRateLimited } from "../_shared/rate_limit.ts";

const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY")!;
const MODEL = "gemini-3.1-flash-lite";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    if (await isRateLimited(req, "gemini")) {
      return new Response(
        JSON.stringify({ error: { message: "rate limited" } }),
        { status: 429, headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const { contents, generationConfig, stream } = await req.json();
    const action = stream ? "streamGenerateContent" : "generateContent";
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:${action}`;

    const upstream = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-goog-api-key": GEMINI_KEY },
      body: JSON.stringify({ contents, generationConfig }),
    });

    // Pipe Gemini's body straight back — same format the Dart parser expects.
    return new Response(upstream.body, {
      status: upstream.status,
      headers: {
        ...cors,
        "Content-Type": upstream.headers.get("Content-Type") ?? "application/json",
      },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: { message: String(e) } }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
