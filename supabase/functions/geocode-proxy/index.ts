import { cors } from "../_shared/cors.ts";
import { isRateLimited } from "../_shared/rate_limit.ts";

const MAPS_KEY = Deno.env.get("GOOGLE_MAPS_API_KEY");
const GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json";
const PLACES_AUTOCOMPLETE_URL =
  "https://places.googleapis.com/v1/places:autocomplete";

type RequestBody = Record<string, unknown>;

type AutocompleteText = {
  text?: string;
};

type AutocompletePrediction = {
  placeId?: string;
  text?: AutocompleteText;
  structuredFormat?: {
    mainText?: AutocompleteText;
    secondaryText?: AutocompleteText;
  };
};

type AutocompleteResponse = {
  suggestions?: Array<{
    placePrediction?: AutocompletePrediction;
  }>;
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function isRecord(value: unknown): value is RequestBody {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function readString(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;

  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed;
}

function readLanguage(value: unknown): string {
  const language = readString(value);
  if (language?.match(/^[a-z]{2,3}(?:-[A-Za-z]{2,4})?$/)) {
    return language;
  }
  return "en";
}

function readCoordinate(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value)
    ? value
    : undefined;
}

function buildGeocodeUrl(body: RequestBody, language: string): URL | undefined {
  if (!MAPS_KEY) return undefined;

  const url = new URL(GEOCODE_URL);
  url.searchParams.set("key", MAPS_KEY);
  url.searchParams.set("language", language);

  const placeId = readString(body.placeId);
  if (placeId) {
    url.searchParams.set("place_id", placeId);
    return url;
  }

  const address = readString(body.address);
  if (address) {
    url.searchParams.set("address", address);
    return url;
  }

  const lat = readCoordinate(body.lat);
  const lon = readCoordinate(body.lon);
  if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
    return undefined;
  }

  url.searchParams.set("latlng", `${lat},${lon}`);
  return url;
}

async function autocompleteCities(
  query: string,
  language: string,
): Promise<Response> {
  if (!MAPS_KEY) {
    return json({ error: { message: "Google Maps is not configured" } }, 500);
  }

  const response = await fetch(PLACES_AUTOCOMPLETE_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": MAPS_KEY,
      "X-Goog-FieldMask": [
        "suggestions.placePrediction.placeId",
        "suggestions.placePrediction.text.text",
        "suggestions.placePrediction.structuredFormat.mainText.text",
        "suggestions.placePrediction.structuredFormat.secondaryText.text",
      ].join(","),
    },
    body: JSON.stringify({
      input: query,
      languageCode: language,
      includedPrimaryTypes: ["(cities)"],
    }),
  });
  const responseText = await response.text();

  if (!response.ok) {
    return new Response(responseText, {
      status: response.status,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  let payload: AutocompleteResponse;
  try {
    payload = JSON.parse(responseText) as AutocompleteResponse;
  } catch (_) {
    return json({ error: { message: "Invalid Places API response" } }, 502);
  }

  const suggestions = (payload.suggestions ?? []).flatMap((suggestion) => {
    const prediction = suggestion.placePrediction;
    const placeId = prediction?.placeId;
    const primaryText = prediction?.structuredFormat?.mainText?.text ??
      prediction?.text?.text;

    if (!placeId || !primaryText) return [];

    return [{
      placeId,
      primaryText,
      secondaryText: prediction?.structuredFormat?.secondaryText?.text ?? "",
    }];
  });

  return json({ suggestions });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    if (await isRateLimited(req, "geocode")) {
      return new Response(
        JSON.stringify({ error: { message: "rate limited" } }),
        { status: 429, headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const body = await req.json();
    if (!isRecord(body)) {
      return json({ error: { message: "Invalid request body" } }, 400);
    }

    const language = readLanguage(body.language);
    if (body.action === "autocomplete") {
      const query = readString(body.query);
      if (!query || query.length < 2) {
        return json({ error: { message: "Query must be at least 2 characters" } }, 400);
      }
      return await autocompleteCities(query, language);
    }

    const url = buildGeocodeUrl(body, language);
    if (!url) {
      return json({ error: { message: "Provide a valid address, place ID, or coordinates" } }, 400);
    }

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
