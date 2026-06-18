import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

function clientIp(req: Request): string {
  const cf = req.headers.get("cf-connecting-ip")?.trim();
  if (cf) return cf;

  const xff = req.headers.get("x-forwarded-for");
  if (xff) {
    const first = xff.split(",")[0].trim();
    if (first) return first;
  }
  return req.headers.get("x-real-ip") ?? "unknown";
}

export async function isRateLimited(req: Request, scope: string): Promise<boolean> {
  try {
    const { data, error } = await admin.rpc("check_rate_limit", {
      p_ip: clientIp(req),
      p_scope: scope,
    });
    if (error) return false;
    return data === true;
  } catch (_) {
    return false;
  }
}
