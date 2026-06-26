import { cors } from "../_shared/cors.ts";

// Per-store "latest published version" lookup. The app sends its detected
// store + identifier; we return that store's live version so a user is only
// ever prompted toward a version their own store actually has.
//
// Version source by store:
//   appStore / macAppStore -> iTunes Lookup JSON
//   microsoftStore         -> DisplayCatalog JSON (version in MSIX full name)
//   snap                   -> snapcraft.io info API (stable channel)
//   appGallery             -> web gateway with interface-code handshake
//   play                   -> store-listing HTML scrape (best-effort)
//
// Override valve (optional safety net, off by default): set the
// VERSION_OVERRIDES secret to a JSON map, e.g.
//   {"play":{"version":"3.5.4","enabled":true}}
// An enabled override is returned verbatim and skips scraping — useful if a
// store changes its format, fixable with no app release.

interface UpdateResult {
  version: string | null;
  url: string | null;
  releaseNotes: string | null;
}

const UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/124.0 Safari/537.36";

const OVERRIDES: Record<
  string,
  { version?: string; url?: string; releaseNotes?: string; enabled?: boolean }
> = (() => {
  try {
    return JSON.parse(Deno.env.get("VERSION_OVERRIDES") ?? "{}");
  } catch {
    return {};
  }
})();

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { store, id, country = "us", lang = "en", locale } = await req.json();

    const overridden = applyOverride(store);
    if (overridden) return json(overridden);

    let result: UpdateResult = empty();
    switch (store) {
      case "appStore":
        result = await fromApple(id, country, "software");
        break;
      case "macAppStore":
        result = await fromApple(id, country, "macSoftware");
        break;
      case "play":
        result = await fromPlay(id, lang, country);
        break;
      case "appGallery":
        result = await fromAppGallery(id, lang, country);
        break;
      case "microsoftStore":
        result = await fromMicrosoft(id, country, locale ?? `${lang}-${country}`);
        break;
      case "snap":
        result = await fromSnap(id);
        break;
      default:
        // unknown -> no result.
        break;
    }
    return json(result);
  } catch (e) {
    // Fail safe: never surface an error as an "update available".
    return json({ ...empty(), error: String(e) });
  }
});

function json(body: unknown) {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function empty(): UpdateResult {
  return { version: null, url: null, releaseNotes: null };
}

function applyOverride(store: string): UpdateResult | null {
  const o = OVERRIDES[store];
  if (o && o.enabled !== false && o.version) {
    return {
      version: o.version,
      url: o.url ?? null,
      releaseNotes: o.releaseNotes ?? null,
    };
  }
  return null;
}

// --- Apple App Store / Mac App Store (robust JSON) -------------------------
async function fromApple(
  bundleId: string,
  country: string,
  entity: string,
): Promise<UpdateResult> {
  const url =
    `https://itunes.apple.com/lookup?bundleId=${encodeURIComponent(bundleId)}` +
    `&country=${encodeURIComponent(country)}&entity=${entity}`;
  const res = await fetch(url, { headers: { Accept: "application/json" } });
  if (!res.ok) return empty();
  const data = await res.json();
  const app = data?.results?.[0];
  if (!app) return empty();
  return {
    version: app.version ?? null,
    url: app.trackViewUrl ?? null,
    releaseNotes: app.releaseNotes ?? null,
  };
}

// --- Google Play (best-effort scrape) --------------------------------------
async function fromPlay(
  pkg: string,
  lang: string,
  country: string,
): Promise<UpdateResult> {
  const url =
    `https://play.google.com/store/apps/details?id=${encodeURIComponent(pkg)}` +
    `&hl=${lang}&gl=${country}`;
  const res = await fetch(url, {
    headers: { "User-Agent": UA, "Accept-Language": lang },
  });
  const fallbackUrl = `https://play.google.com/store/apps/details?id=${pkg}`;
  if (!res.ok) return { ...empty(), url: fallbackUrl };
  const html = await res.text();

  let version: string | null = null;
  // Play embeds the version in a JS data blob; these patterns have proven the
  // most durable. Any miss simply yields null (no prompt).
  for (
    const re of [
      /\[\[\["((?:\d+\.)+\d+)"\]\]/,
      /"softwareVersion"\s*:\s*"((?:\d+\.)+\d+)"/i,
      /Current Version[\s\S]{0,160}?((?:\d+\.)+\d+)/i,
    ]
  ) {
    const m = html.match(re);
    if (m) {
      version = m[1];
      break;
    }
  }

  let notes: string | null = null;
  const rn = html.match(
    /itemprop="description"[^>]*>([\s\S]{0,1500}?)<\/div>/i,
  );
  if (rn) notes = stripHtml(rn[1]);

  return { version, url: fallbackUrl, releaseNotes: notes };
}

// --- Huawei AppGallery -----------------------------------------------------
// `id` here is the AppGallery content id (e.g. "C115050257"), not the package.
// The web gateway needs a short-lived, User-Agent-bound interface code fetched
// from /webedge/getInterfaceCode, then sent as the `Interface-Code` header
// ("<code>_<timestamp>") on the detail call — the same handshake the website
// performs. The detail JSON exposes the live marketing version as
// `"versionName":"x.y.z"`. The "Update" button uses the appmarket:// deep link
// from AppStoreInfo (we return url: null here).
async function fromAppGallery(
  contentId: string,
  lang: string,
  country: string,
): Promise<UpdateResult> {
  const base = "https://web-dra.hispace.dbankcloud.com/edge";
  const referer = "https://appgallery.huawei.com/";
  try {
    const codeRes = await fetch(`${base}/webedge/getInterfaceCode`, {
      headers: { "User-Agent": UA, Referer: referer },
    });
    if (!codeRes.ok) return empty();
    // Body is a quoted JWT string; strip the surrounding quotes.
    const code = (await codeRes.text()).trim().replace(/^"|"$/g, "");
    if (!code) return empty();

    const locale = `${lang}_${country.toUpperCase()}`;
    const detailUrl =
      `${base}/uowap/index?method=internal.getTabDetail&serviceType=20` +
      `&reqPageType=20&uri=${encodeURIComponent("app|" + contentId)}` +
      `&locale=${locale}`;
    const res = await fetch(detailUrl, {
      headers: {
        "User-Agent": UA,
        Referer: referer,
        "Interface-Code": `${code}_${Date.now()}`,
      },
    });
    if (!res.ok) return empty();
    const text = await res.text();
    const m = text.match(/"versionName"\s*:\s*"((?:\d+\.)+\d+)"/);
    return { version: m ? m[1] : null, url: null, releaseNotes: null };
  } catch {
    return empty();
  }
}

// --- Microsoft Store (DisplayCatalog JSON) ---------------------------------
// The MSIX package full name embeds the version: Name_X.Y.Z.W_arch__publisher.
async function fromMicrosoft(
  productId: string,
  country: string,
  locale: string,
): Promise<UpdateResult> {
  const fallbackUrl = `https://apps.microsoft.com/detail/${productId}`;
  try {
    const url =
      `https://displaycatalog.mp.microsoft.com/v7.0/products` +
      `?bigIds=${productId.toUpperCase()}&market=${country.toUpperCase()}` +
      `&languages=${locale.toLowerCase()}`;
    const res = await fetch(url, { headers: { "User-Agent": UA } });
    if (!res.ok) return { ...empty(), url: fallbackUrl };
    const text = await res.text();
    const m = text.match(/_(\d+\.\d+\.\d+\.\d+)_(?:x64|x86|arm64|neutral)__/i);
    return { version: m ? m[1] : null, url: fallbackUrl, releaseNotes: null };
  } catch {
    return { ...empty(), url: fallbackUrl };
  }
}

// --- Snap Store (snapcraft.io info API) ------------------------------------
// `id` is the snap name (e.g. "huda"). The stable channel's version is the
// live published one. (Snaps auto-refresh, but we still surface it.)
async function fromSnap(snapName: string): Promise<UpdateResult> {
  const storeUrl = `https://snapcraft.io/${snapName}`;
  try {
    const res = await fetch(
      `https://api.snapcraft.io/v2/snaps/info/${encodeURIComponent(snapName)}`,
      { headers: { "Snap-Device-Series": "16", "User-Agent": UA } },
    );
    if (!res.ok) return { ...empty(), url: storeUrl };
    const data = await res.json();
    const map: Array<{ channel?: { risk?: string }; version?: string }> =
      Array.isArray(data?.["channel-map"]) ? data["channel-map"] : [];
    const entry = map.find((e) => e?.channel?.risk === "stable") ?? map[0];
    return {
      version: entry?.version ?? null,
      url: data?.snap?.["store-url"] ?? storeUrl,
      releaseNotes: null,
    };
  } catch {
    return { ...empty(), url: storeUrl };
  }
}

function stripHtml(s: string): string {
  return s
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&gt;/g, ">")
    .replace(/&lt;/g, "<")
    .replace(/\s+\n/g, "\n")
    .trim();
}
