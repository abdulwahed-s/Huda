import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Per-IP, per-day cap shared by every proxy function. The anon key is
// extractable from the shipped app, so this is the cheap abuse brake.
const DAILY_LIMIT = 100;

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

/**
 * Atomically increments today's request count for the caller's IP and returns
 * whether the caller is now over the daily limit. Fails open: if the counter
 * itself errors we let the request through rather than breaking the app.
 */
export async function isRateLimited(req: Request): Promise<boolean> {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0].trim() ?? "unknown";
  const today = new Date().toISOString().slice(0, 10);

  const { data, error } = await admin.rpc("increment_api_usage", {
    p_ip: ip,
    p_day: today,
  });

  if (error) return false;
  return (data ?? 0) > DAILY_LIMIT;
}
