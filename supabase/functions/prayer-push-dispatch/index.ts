import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID") ?? "";
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID") ?? "";
const APNS_TOPIC = Deno.env.get("APNS_TOPIC") ?? "com.aw.huda";
const APNS_PRIVATE_KEY_BASE64 = Deno.env.get("APNS_PRIVATE_KEY_BASE64") ?? "";
const APNS_PRIVATE_KEY = Deno.env.get("APNS_PRIVATE_KEY") ?? "";

type CompactEvent = [number, number, string];

interface Installation {
  installation_id: string;
  apns_token: string;
  apns_environment: "development" | "production";
  bundle_id: string;
  local_coverage_until: string | null;
  next_event_index: number | null;
  failure_count: number;
  event_epoch: number | string;
  notification_id: number;
  prayer: string;
  title: string;
  body: string;
}

let cachedProviderToken: { token: string; createdAt: number } | null = null;
let providerTokenPromise: Promise<string> | null = null;
let signingKeyPromise: Promise<CryptoKey> | null = null;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return response({ error: "method_not_allowed" }, 405);
  }

  try {
    if (!await isAuthorized(req)) {
      return response({ error: "unauthorized" }, 401);
    }
    validateConfiguration();

    const { data, error } = await admin.rpc("claim_due_prayer_pushes", {
      p_limit: 250,
    });
    if (error) throw error;

    const installations = (data ?? []) as Installation[];
    const results = await Promise.allSettled(
      installations.map((installation) => processInstallation(installation)),
    );
    let delivered = 0;
    let skipped = 0;
    let failed = 0;
    for (const result of results) {
      if (result.status === "rejected") {
        failed++;
        console.error("prayer push row failed", safeError(result.reason));
      } else if (result.value === "delivered") {
        delivered++;
      } else if (result.value === "failed") {
        failed++;
      } else {
        skipped++;
      }
    }

    return response({
      ok: true,
      claimed: installations.length,
      delivered,
      skipped,
      failed,
    });
  } catch (error) {
    console.error("prayer-push-dispatch failed", safeError(error));
    return response({ error: "internal_error" }, 500);
  }
});

async function processInstallation(
  installation: Installation,
): Promise<"delivered" | "skipped" | "failed"> {
  const index = installation.next_event_index;
  const eventEpoch = Number(installation.event_epoch);
  const event: CompactEvent = [
    eventEpoch,
    installation.notification_id,
    installation.prayer,
  ];
  if (
    index === null ||
    index < 0 ||
    !validEvent(event) ||
    typeof installation.title !== "string" ||
    !installation.title ||
    typeof installation.body !== "string" ||
    !installation.body
  ) {
    await disableMalformed(installation.installation_id, "Malformed schedule");
    return "skipped";
  }

  const nowEpoch = Math.floor(Date.now() / 1000);
  const coverageEpoch = installation.local_coverage_until
    ? Math.floor(new Date(installation.local_coverage_until).getTime() / 1000)
    : 0;
  // Never deliver an alert more than ten minutes after its prayer time. Skip
  // stale events after a provider outage instead of presenting a burst.
  const staleBefore = nowEpoch - 10 * 60;
  if (eventEpoch <= coverageEpoch || eventEpoch < staleBefore) {
    await advance(installation, {
      status: null,
      error: null,
      delivered: false,
    });
    return "skipped";
  }

  if (eventEpoch > nowEpoch) {
    const { error } = await admin
      .from("prayer_push_installations")
      .update({
        next_notification_at: new Date(eventEpoch * 1000).toISOString(),
        lease_until: null,
        updated_at: new Date().toISOString(),
      })
      .eq("installation_id", installation.installation_id)
      .eq("next_event_index", index);
    if (error) throw error;
    return "skipped";
  }

  const apns = await sendApnsWithEnvironmentRecovery(installation, event, {
    title: installation.title,
    body: installation.body,
  });
  if (apns.ok) {
    await advance(installation, {
      status: apns.status,
      error: null,
      delivered: true,
    });
    return "delivered";
  }

  if (isPermanentTokenFailure(apns.status, apns.reason)) {
    const { error } = await admin
      .from("prayer_push_installations")
      .update({
        enabled: false,
        next_notification_at: null,
        lease_until: null,
        last_apns_status: apns.status,
        last_error: apns.reason,
        failure_count: installation.failure_count + 1,
        updated_at: new Date().toISOString(),
      })
      .eq("installation_id", installation.installation_id);
    if (error) throw error;
    return "failed";
  }

  const failures = installation.failure_count + 1;
  if (failures >= 5) {
    // Preserve later prayers while abandoning one event that could no longer
    // be delivered near its intended time.
    await advance(installation, {
      status: apns.status,
      error: apns.reason,
      delivered: false,
      failureCount: failures,
    });
  } else {
    const retryMinutes = Math.min(2 ** failures, 10);
    const { error } = await admin
      .from("prayer_push_installations")
      .update({
        next_event_index: index,
        next_notification_at: new Date(
          Date.now() + retryMinutes * 60 * 1000,
        ).toISOString(),
        lease_until: null,
        failure_count: failures,
        last_apns_status: apns.status,
        last_error: apns.reason,
        updated_at: new Date().toISOString(),
      })
      .eq("installation_id", installation.installation_id)
      .eq("next_event_index", index);
    if (error) throw error;
  }
  return "failed";
}

async function advance(
  installation: Installation,
  outcome: {
    status: number | null;
    error: string | null;
    delivered: boolean;
    failureCount?: number;
  },
): Promise<void> {
  if (installation.next_event_index === null) return;
  const { error } = await admin.rpc("advance_prayer_push", {
    p_installation_id: installation.installation_id,
    p_expected_event_index: installation.next_event_index,
    p_apns_status: outcome.status,
    p_error: outcome.error,
    p_delivered: outcome.delivered,
    p_failure_count: outcome.failureCount ?? 0,
  });
  if (error) throw error;
}

// Keeping each installation's year-long schedule in Postgres avoids sending
// location data. Only the current compact event reaches this worker; advancing
// to the next event is performed by the database RPC above.

async function disableMalformed(installationId: string, message: string) {
  const { error } = await admin
    .from("prayer_push_installations")
    .update({
      enabled: false,
      next_notification_at: null,
      lease_until: null,
      last_error: message,
      updated_at: new Date().toISOString(),
    })
    .eq("installation_id", installationId);
  if (error) throw error;
}

async function sendApns(
  installation: Installation,
  event: CompactEvent,
  content: { title: string; body: string },
): Promise<{ ok: boolean; status: number; reason: string | null }> {
  const providerToken = await providerJwt();
  const host = installation.apns_environment === "development"
    ? "api.sandbox.push.apple.com"
    : "api.push.apple.com";
  const payload = {
    aps: {
      alert: { title: content.title, body: content.body },
      sound: "adhan.caf",
      "thread-id": "prayer-times",
      "interruption-level": "time-sensitive",
    },
    type: "prayer_time",
    prayer: event[2],
    notificationId: event[1],
    scheduledTime: new Date(event[0] * 1000).toISOString(),
  };

  try {
    const result = await fetch(
      `https://${host}/3/device/${installation.apns_token}`,
      {
        method: "POST",
        headers: {
          authorization: `bearer ${providerToken}`,
          "apns-topic": APNS_TOPIC,
          "apns-push-type": "alert",
          "apns-priority": "10",
          // Do not let APNs present a stale prayer alert long after its time.
          "apns-expiration": String(event[0] + 10 * 60),
          "apns-collapse-id": `prayer-${event[1]}`,
          "content-type": "application/json",
        },
        body: JSON.stringify(payload),
      },
    );
    let reason: string | null = null;
    if (!result.ok) {
      try {
        reason = (await result.json())?.reason ?? `HTTP ${result.status}`;
      } catch {
        reason = `HTTP ${result.status}`;
      }
    }
    return { ok: result.ok, status: result.status, reason };
  } catch (error) {
    return { ok: false, status: 0, reason: safeError(error) };
  }
}

async function sendApnsWithEnvironmentRecovery(
  installation: Installation,
  event: CompactEvent,
  content: { title: string; body: string },
): Promise<{ ok: boolean; status: number; reason: string | null }> {
  const initial = await sendApns(installation, event, content);
  if (initial.ok || initial.reason !== "BadDeviceToken") return initial;

  // Xcode normally derives aps-environment from the provisioning profile, but
  // custom release/development signing can differ from the build configuration
  // reported by the app. APNs token keys work in both environments, so recover
  // once from that mismatch before treating the token as invalid.
  const correctedEnvironment = installation.apns_environment === "development"
    ? "production"
    : "development";
  const corrected = await sendApns(
    { ...installation, apns_environment: correctedEnvironment },
    event,
    content,
  );
  if (!corrected.ok) return corrected;

  const now = new Date().toISOString();
  const { error: duplicateError } = await admin
    .from("prayer_push_installations")
    .update({
      enabled: false,
      next_notification_at: null,
      lease_until: null,
      updated_at: now,
    })
    .eq("apns_token", installation.apns_token)
    .eq("apns_environment", correctedEnvironment)
    .neq("installation_id", installation.installation_id);
  if (duplicateError) throw duplicateError;

  const { error: correctionError } = await admin
    .from("prayer_push_installations")
    .update({
      apns_environment: correctedEnvironment,
      updated_at: now,
    })
    .eq("installation_id", installation.installation_id)
    .eq("apns_token", installation.apns_token);
  if (correctionError) throw correctionError;
  return corrected;
}

async function providerJwt(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedProviderToken && now - cachedProviderToken.createdAt < 50 * 60) {
    return cachedProviderToken.token;
  }

  providerTokenPromise ??= refreshProviderJwt().finally(() => {
    providerTokenPromise = null;
  });
  return providerTokenPromise;
}

async function refreshProviderJwt(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const { data: stored, error: storedError } = await admin
    .from("prayer_push_private_config")
    .select("value")
    .eq("key", "apns_provider_token")
    .maybeSingle();
  if (storedError) throw storedError;
  if (stored?.value) {
    try {
      const parsed = JSON.parse(stored.value);
      if (
        parsed.keyId === APNS_KEY_ID &&
        typeof parsed.token === "string" &&
        Number.isSafeInteger(parsed.createdAt) &&
        now - parsed.createdAt < 50 * 60
      ) {
        cachedProviderToken = {
          token: parsed.token,
          createdAt: parsed.createdAt,
        };
        return parsed.token;
      }
    } catch {
      // Replace malformed private cache data below.
    }
  }

  const header = base64UrlText(
    JSON.stringify({ alg: "ES256", kid: APNS_KEY_ID }),
  );
  const claims = base64UrlText(JSON.stringify({ iss: APNS_TEAM_ID, iat: now }));
  const signingInput = `${header}.${claims}`;
  const key = await signingKey();
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      key,
      new TextEncoder().encode(signingInput),
    ),
  );
  const joseSignature = ecdsaJoseSignature(signature);
  const candidate = `${signingInput}.${base64UrlBytes(joseSignature)}`;
  const { data: selected, error } = await admin.rpc(
    "get_or_store_apns_provider_token",
    {
      p_token: candidate,
      p_created_at: now,
      p_key_id: APNS_KEY_ID,
    },
  );
  if (error) throw error;
  if (
    !selected ||
    typeof selected.token !== "string" ||
    !Number.isSafeInteger(selected.createdAt)
  ) {
    throw new Error("Invalid provider token cache response");
  }
  cachedProviderToken = {
    token: selected.token,
    createdAt: selected.createdAt,
  };
  return selected.token;
}

function signingKey(): Promise<CryptoKey> {
  signingKeyPromise ??= crypto.subtle.importKey(
    "pkcs8",
    privateKeyDer(),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  return signingKeyPromise;
}

function privateKeyDer(): Uint8Array {
  let pem = APNS_PRIVATE_KEY;
  if (APNS_PRIVATE_KEY_BASE64) {
    pem = atob(APNS_PRIVATE_KEY_BASE64.replace(/\s/g, ""));
  }
  pem = pem.replace(/\\n/g, "\n");
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(base64);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

// WebCrypto returns a 64-byte IEEE-P1363 signature in current Edge runtimes.
// Accept DER too so a runtime implementation change cannot invalidate APNs
// provider tokens.
function ecdsaJoseSignature(signature: Uint8Array): Uint8Array {
  if (signature.length === 64) return signature;
  if (signature[0] !== 0x30) throw new Error("Unsupported ECDSA signature");
  let offset = signature[1] & 0x80 ? 2 + (signature[1] & 0x7f) : 2;
  if (signature[offset++] !== 0x02) throw new Error("Invalid ECDSA signature");
  const rLength = signature[offset++];
  const r = signature.slice(offset, offset + rLength);
  offset += rLength;
  if (signature[offset++] !== 0x02) throw new Error("Invalid ECDSA signature");
  const sLength = signature[offset++];
  const s = signature.slice(offset, offset + sLength);
  const output = new Uint8Array(64);
  output.set(r.slice(Math.max(0, r.length - 32)), Math.max(0, 32 - r.length));
  output.set(
    s.slice(Math.max(0, s.length - 32)),
    32 + Math.max(0, 32 - s.length),
  );
  return output;
}

async function isAuthorized(req: Request): Promise<boolean> {
  const supplied = req.headers.get("x-prayer-push-dispatch-key") ?? "";
  if (!supplied) return false;
  const { data, error } = await admin
    .from("prayer_push_private_config")
    .select("value")
    .eq("key", "dispatch_key")
    .single();
  if (error || !data?.value) return false;
  return constantTimeEqual(supplied, data.value);
}

function isPermanentTokenFailure(
  status: number,
  reason: string | null,
): boolean {
  return status === 410 ||
    reason === "BadDeviceToken" ||
    reason === "DeviceTokenNotForTopic" ||
    reason === "Unregistered";
}

function validEvent(value: unknown): value is CompactEvent {
  return Array.isArray(value) &&
    value.length === 3 &&
    Number.isSafeInteger(value[0]) &&
    Number.isSafeInteger(value[1]) &&
    typeof value[2] === "string";
}

function validateConfiguration() {
  if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_TOPIC) {
    throw new Error("APNs metadata secrets are missing");
  }
  if (!APNS_PRIVATE_KEY_BASE64 && !APNS_PRIVATE_KEY) {
    throw new Error("APNs private key secret is missing");
  }
}

function base64UrlText(value: string): string {
  return base64UrlBytes(new TextEncoder().encode(value));
}

function base64UrlBytes(value: Uint8Array): string {
  let binary = "";
  for (const byte of value) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function constantTimeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index++) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

function response(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function safeError(error: unknown): string {
  return error instanceof Error
    ? `${error.name}: ${error.message}`
    : String(error);
}
