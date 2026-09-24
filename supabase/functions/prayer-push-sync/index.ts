import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { cors } from "../_shared/cors.ts";
import { isPrayerPushRateLimited } from "../_shared/rate_limit.ts";
import {
  canonicalizeLegacyPrayerContent,
  canonicalPrayerContent,
  normalizeLocale,
  PrayerPushInputError,
  validatePrayerEvents,
  validatePrayerPushRevisions,
} from "../_shared/prayer_push_validation.ts";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const tokenPattern = /^(?:[0-9a-f]{2}){16,256}$/i;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    const payload = await req.json();
    const installationId = requiredString(payload.installationId, 36);
    const installationSecret = requiredString(payload.installationSecret, 128);
    if (!uuidPattern.test(installationId) || installationSecret.length < 32) {
      return json({ error: "invalid_installation" }, 400);
    }

    const secretHash = await sha256(installationSecret);
    const { data: existing, error: lookupError } = await admin
      .from("prayer_push_installations")
      .select("installation_secret_hash,schedule_revision")
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
      const revisions = validatePrayerPushRevisions(
        payload.locationRevision,
        payload.scheduleRevision,
      );
      if (existing) {
        const { data, error } = await admin.rpc(
          "disable_prayer_push_installation_v2",
          {
            p_installation_id: installationId,
            p_installation_secret_hash: secretHash,
            p_location_revision: revisions.locationRevision,
            p_schedule_revision: revisions.scheduleRevision,
          },
        );
        if (error) throw error;
        const result = firstRpcRow(data);
        if (result.status === "invalid_installation") {
          return json({ error: result.status }, 403);
        }
        if (result.status === "stale_revision") {
          return json(
            {
              error: result.status,
              acceptedScheduleRevision: result.accepted_schedule_revision,
              acceptedLocationRevision: result.accepted_location_revision,
            },
            409,
          );
        }
        if (result.status !== "accepted" && result.status !== "absent") {
          return json({ error: result.status || "disable_rejected" }, 400);
        }
        return json({
          ok: true,
          enabled: false,
          acceptedScheduleRevision: result.accepted_schedule_revision,
          acceptedLocationRevision: result.accepted_location_revision,
        });
      }
      return json({
        ok: true,
        enabled: false,
        acceptedScheduleRevision: revisions.scheduleRevision,
        acceptedLocationRevision: revisions.locationRevision,
      });
    }

    if (payload.action !== "sync") {
      return json({ error: "invalid_action" }, 400);
    }

    if (await isPrayerPushRateLimited(req, installationId, existing !== null)) {
      return json({ error: "rate_limited" }, 429);
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

    const requestedLocale = optionalString(payload.locale, 20);
    const locale =
      requestedLocale === null ? null : normalizeLocale(requestedLocale);
    const content =
      locale === null
        ? canonicalizeLegacyPrayerContent(payload.content)
        : canonicalPrayerContent(locale);
    const events = validatePrayerEvents(payload.events);
    if (events.length === 0) return json({ error: "empty_schedule" }, 400);
    const revisions = validatePrayerPushRevisions(
      payload.locationRevision,
      payload.scheduleRevision,
    );

    const localCoverage = optionalDate(payload.localCoverageUntil);
    const nowEpoch = Math.floor(Date.now() / 1000);
    const threshold = Math.max(
      nowEpoch - 60,
      localCoverage ? Math.floor(localCoverage.getTime() / 1000) : 0,
    );
    const nextIndex = events.findIndex((event) => event[0] > threshold);
    const nextNotificationAt =
      nextIndex < 0
        ? null
        : new Date(events[nextIndex][0] * 1000).toISOString();
    const scheduleThrough = new Date(
      events[events.length - 1][0] * 1000,
    ).toISOString();

    const { data: syncResult, error: upsertError } = await admin.rpc(
      "sync_prayer_push_installation_v2",
      {
        p_installation_id: installationId,
        p_installation_secret_hash: secretHash,
        p_apns_token: token,
        p_apns_environment: environment,
        p_bundle_id: bundleId,
        p_app_version: appVersion,
        p_time_zone: timeZone,
        p_configuration_signature: configurationSignature,
        p_local_coverage_until: localCoverage?.toISOString() ?? null,
        p_schedule_through: scheduleThrough,
        p_schedule: { content, events },
        p_next_event_index: nextIndex < 0 ? null : nextIndex,
        p_next_notification_at: nextNotificationAt,
        p_location_revision: revisions.locationRevision,
        p_schedule_revision: revisions.scheduleRevision,
      },
    );
    if (upsertError) throw upsertError;
    const accepted = firstRpcRow(syncResult);
    if (accepted.status === "invalid_installation") {
      return json({ error: "invalid_installation" }, 403);
    }
    if (
      accepted.status === "stale_revision" ||
      accepted.status === "revision_conflict"
    ) {
      return json(
        {
          error: accepted.status,
          acceptedScheduleRevision: accepted.accepted_schedule_revision,
          acceptedLocationRevision: accepted.accepted_location_revision,
          acknowledgedLocalCoverageUntil:
            accepted.acknowledged_local_coverage_until,
        },
        409,
      );
    }
    if (accepted.status !== "accepted" && accepted.status !== "idempotent") {
      return json({ error: accepted.status || "sync_rejected" }, 400);
    }

    return json({
      ok: true,
      enabled: true,
      eventCount: events.length,
      localCoverageUntil: localCoverage?.toISOString() ?? null,
      nextNotificationAt,
      scheduleThrough,
      acceptedScheduleRevision: accepted.accepted_schedule_revision,
      acceptedLocationRevision: accepted.accepted_location_revision,
      acknowledgedLocalCoverageUntil:
        accepted.acknowledged_local_coverage_until,
      idempotent: accepted.status === "idempotent",
    });
  } catch (error) {
    console.error("prayer-push-sync failed", safeError(error));
    if (error instanceof InputError || error instanceof PrayerPushInputError) {
      return json({ error: error.code }, 400);
    }
    return json({ error: "internal_error" }, 500);
  }
});

function firstRpcRow(value: unknown): Record<string, any> {
  const row = Array.isArray(value) ? value[0] : value;
  if (!row || typeof row !== "object") {
    throw new Error("Invalid prayer-push RPC response");
  }
  return row as Record<string, any>;
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
