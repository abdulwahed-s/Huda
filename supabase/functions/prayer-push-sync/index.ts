import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { cors } from "../_shared/cors.ts";
import { isRateLimited } from "../_shared/rate_limit.ts";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

const allowedPrayers = new Set(["fajr", "dhuhr", "asr", "maghrib", "isha"]);
const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const tokenPattern = /^(?:[0-9a-f]{2}){16,256}$/i;

type Content = Record<string, { title: string; body: string }>;
type CompactEvent = [number, number, string];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    if (await isRateLimited(req, "prayer-push-sync")) {
      return json({ error: "rate_limited" }, 429);
    }

    const payload = await req.json();
    const installationId = requiredString(payload.installationId, 36);
    const installationSecret = requiredString(payload.installationSecret, 128);
    if (!uuidPattern.test(installationId) || installationSecret.length < 32) {
      return json({ error: "invalid_installation" }, 400);
    }

    const secretHash = await sha256(installationSecret);
    const { data: existing, error: lookupError } = await admin
      .from("prayer_push_installations")
      .select("installation_secret_hash")
      .eq("installation_id", installationId)
      .maybeSingle();
    if (lookupError) throw lookupError;
    if (
      existing &&
      !constantTimeEqual(existing.installation_secret_hash, secretHash)
    ) {
      return json({ error: "invalid_installation" }, 403);
    }

    if (payload.action === "disable") {
      if (existing) {
        const { error } = await admin
          .from("prayer_push_installations")
          .delete()
          .eq("installation_id", installationId);
        if (error) throw error;
      }
      return json({ ok: true, enabled: false });
    }

    if (payload.action !== "sync") {
      return json({ error: "invalid_action" }, 400);
    }

    const token = requiredString(payload.deviceToken, 512).toLowerCase();
    const environment = requiredString(payload.environment, 20);
    const bundleId = requiredString(payload.bundleId, 100);
    const timeZone = requiredString(payload.timeZone, 100);
    const configurationSignature = requiredString(
      payload.configurationSignature,
      1500,
    );
    const appVersion = optionalString(payload.appVersion, 60);
    if (!tokenPattern.test(token)) return json({ error: "invalid_token" }, 400);
    if (environment !== "development" && environment !== "production") {
      return json({ error: "invalid_environment" }, 400);
    }
    if (bundleId !== "com.aw.huda") {
      return json({ error: "invalid_bundle" }, 400);
    }

    const content = validateContent(payload.content);
    const events = validateEvents(payload.events, content);
    if (events.length === 0) return json({ error: "empty_schedule" }, 400);

    const localCoverage = optionalDate(payload.localCoverageUntil);
    const nowEpoch = Math.floor(Date.now() / 1000);
    const threshold = Math.max(
      nowEpoch - 60,
      localCoverage ? Math.floor(localCoverage.getTime() / 1000) : 0,
    );
    const nextIndex = events.findIndex((event) => event[0] > threshold);
    const nextNotificationAt = nextIndex < 0
      ? null
      : new Date(events[nextIndex][0] * 1000).toISOString();
    const scheduleThrough = new Date(events[events.length - 1][0] * 1000)
      .toISOString();

    // A token can survive an app reinstall. Disable stale installation rows so
    // one physical app installation never receives duplicate pushes.
    const { error: duplicateError } = await admin
      .from("prayer_push_installations")
      .update({
        enabled: false,
        next_notification_at: null,
        lease_until: null,
        updated_at: new Date().toISOString(),
      })
      .eq("apns_token", token)
      .eq("apns_environment", environment)
      .neq("installation_id", installationId);
    if (duplicateError) throw duplicateError;

    const row = {
      installation_id: installationId,
      installation_secret_hash: secretHash,
      apns_token: token,
      apns_environment: environment,
      bundle_id: bundleId,
      enabled: true,
      app_version: appVersion,
      time_zone: timeZone,
      configuration_signature: configurationSignature,
      local_coverage_until: localCoverage?.toISOString() ?? null,
      schedule_through: scheduleThrough,
      schedule: { content, events },
      next_event_index: nextIndex < 0 ? null : nextIndex,
      next_notification_at: nextNotificationAt,
      lease_until: null,
      failure_count: 0,
      last_apns_status: null,
      last_error: null,
      last_seen_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    const { error: upsertError } = await admin
      .from("prayer_push_installations")
      .upsert(row, { onConflict: "installation_id" });
    if (upsertError) throw upsertError;

    return json({
      ok: true,
      enabled: true,
      eventCount: events.length,
      localCoverageUntil: localCoverage?.toISOString() ?? null,
      nextNotificationAt,
      scheduleThrough,
    });
  } catch (error) {
    console.error("prayer-push-sync failed", safeError(error));
    if (error instanceof InputError) {
      return json({ error: error.code }, 400);
    }
    return json({ error: "internal_error" }, 500);
  }
});

function validateContent(value: unknown): Content {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new InputError("invalid_content");
  }
  const result: Content = {};
  for (const [prayer, raw] of Object.entries(value)) {
    if (!allowedPrayers.has(prayer) || !raw || typeof raw !== "object") {
      throw new InputError("invalid_content");
    }
    const item = raw as Record<string, unknown>;
    result[prayer] = {
      title: requiredString(item.title, 180),
      body: requiredString(item.body, 500),
    };
  }
  return result;
}

function validateEvents(value: unknown, content: Content): CompactEvent[] {
  if (!Array.isArray(value) || value.length > 1900) {
    throw new InputError("invalid_events");
  }

  const earliest = Math.floor(Date.now() / 1000) - 24 * 60 * 60;
  const latest = Math.floor(Date.now() / 1000) + 380 * 24 * 60 * 60;
  let previousEpoch = 0;
  const result: CompactEvent[] = [];
  for (const raw of value) {
    if (!Array.isArray(raw) || raw.length !== 3) {
      throw new InputError("invalid_events");
    }
    const [epoch, notificationId, prayer] = raw;
    if (
      !Number.isSafeInteger(epoch) ||
      epoch < earliest ||
      epoch > latest ||
      epoch <= previousEpoch ||
      !Number.isSafeInteger(notificationId) ||
      notificationId < 0 ||
      notificationId > 2147483647 ||
      typeof prayer !== "string" ||
      !allowedPrayers.has(prayer) ||
      !content[prayer]
    ) {
      throw new InputError("invalid_events");
    }
    previousEpoch = epoch;
    result.push([epoch, notificationId, prayer]);
  }
  return result;
}

function requiredString(value: unknown, maxLength: number): string {
  if (typeof value !== "string") throw new InputError("invalid_payload");
  const normalized = value.trim();
  if (!normalized || normalized.length > maxLength) {
    throw new InputError("invalid_payload");
  }
  return normalized;
}

function optionalString(value: unknown, maxLength: number): string | null {
  if (value === null || value === undefined) return null;
  return requiredString(value, maxLength);
}

function optionalDate(value: unknown): Date | null {
  if (value === null || value === undefined) return null;
  if (typeof value !== "string") throw new InputError("invalid_date");
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) throw new InputError("invalid_date");
  return date;
}

async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function constantTimeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index++) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function safeError(error: unknown): string {
  return error instanceof Error
    ? `${error.name}: ${error.message}`
    : String(error);
}

class InputError extends Error {
  constructor(readonly code: string) {
    super(code);
    this.name = "InputError";
  }
}
