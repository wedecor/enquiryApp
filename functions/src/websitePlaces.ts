import { timingSafeEqual } from "crypto";
import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import {
  buildAutocompleteBody,
  isValidPlaceId,
  isValidSessionToken,
  normalizeAutocompleteInput,
  parseAutocompleteResponse,
  parsePlaceDetails,
  PLACE_DETAILS_FIELD_MASK,
} from "./placesLogic";

/**
 * Public website (server-to-server) wrappers around Places Autocomplete (New).
 * Same Bangalore bias and field mask as the signed-in app callables.
 *
 * Auth: `X-Lead-Secret` = WEBSITE_LEAD_SECRET. Called only from the Next.js
 * `/api/places/*` routes — never from the browser.
 */
const WEBSITE_LEAD_SECRET = defineSecret("WEBSITE_LEAD_SECRET");
const GOOGLE_MAPS_API_KEY = defineSecret("GOOGLE_MAPS_API_KEY");

const PLACES_BASE = "https://places.googleapis.com/v1";
const REQUEST_TIMEOUT_MS = 5000;

function secretMatches(given: string | undefined, expected: string): boolean {
  if (!given || !expected) return false;
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
}

function apiKey(): string {
  try {
    return GOOGLE_MAPS_API_KEY.value() || "";
  } catch {
    return "";
  }
}

async function placesJson(
  url: string,
  init: RequestInit,
  op: string,
): Promise<{ ok: true; json: unknown } | { ok: false; status: number }> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const response = await fetch(url, { ...init, signal: controller.signal });
    if (!response.ok) {
      logger.warn(`${op}: Places API error`, { status: response.status });
      return { ok: false, status: response.status };
    }
    return { ok: true, json: await response.json() };
  } catch (e) {
    const aborted = (e as { name?: string })?.name === "AbortError";
    logger.warn(`${op}: request failed`, { aborted });
    return { ok: false, status: aborted ? 504 : 502 };
  } finally {
    clearTimeout(timer);
  }
}

export const websitePlacesAutocomplete = onRequest(
  {
    secrets: [WEBSITE_LEAD_SECRET, GOOGLE_MAPS_API_KEY],
    invoker: "public",
    cors: false,
    maxInstances: 5,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method not allowed" });
      return;
    }
    if (!secretMatches(req.get("x-lead-secret"), WEBSITE_LEAD_SECRET.value())) {
      res.status(401).json({ ok: false, error: "unauthorized" });
      return;
    }
    const body = (req.body ?? {}) as { input?: unknown; sessionToken?: unknown };
    const input = normalizeAutocompleteInput(body.input);
    if (!input) {
      res.status(400).json({ ok: false, error: "input must be 2 to 100 characters" });
      return;
    }
    if (!isValidSessionToken(body.sessionToken)) {
      res.status(400).json({ ok: false, error: "sessionToken is required" });
      return;
    }
    const key = apiKey();
    if (!key) {
      res.status(503).json({ ok: false, error: "maps not configured" });
      return;
    }
    const result = await placesJson(
      `${PLACES_BASE}/places:autocomplete`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Goog-Api-Key": key },
        body: JSON.stringify(buildAutocompleteBody(input, body.sessionToken)),
      },
      "websitePlacesAutocomplete",
    );
    if (!result.ok) {
      res.status(502).json({ ok: false, error: "maps unavailable" });
      return;
    }
    const suggestions = parseAutocompleteResponse(result.json);
    res.status(200).json({ ok: true, suggestions });
  },
);

export const websitePlaceDetails = onRequest(
  {
    secrets: [WEBSITE_LEAD_SECRET, GOOGLE_MAPS_API_KEY],
    invoker: "public",
    cors: false,
    maxInstances: 5,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method not allowed" });
      return;
    }
    if (!secretMatches(req.get("x-lead-secret"), WEBSITE_LEAD_SECRET.value())) {
      res.status(401).json({ ok: false, error: "unauthorized" });
      return;
    }
    const body = (req.body ?? {}) as { placeId?: unknown; sessionToken?: unknown };
    if (!isValidPlaceId(body.placeId)) {
      res.status(400).json({ ok: false, error: "placeId is required" });
      return;
    }
    if (!isValidSessionToken(body.sessionToken)) {
      res.status(400).json({ ok: false, error: "sessionToken is required" });
      return;
    }
    const key = apiKey();
    if (!key) {
      res.status(503).json({ ok: false, error: "maps not configured" });
      return;
    }
    const url =
      `${PLACES_BASE}/places/${encodeURIComponent(body.placeId)}` +
      `?sessionToken=${encodeURIComponent(body.sessionToken)}`;
    const result = await placesJson(
      url,
      {
        method: "GET",
        headers: { "X-Goog-Api-Key": key, "X-Goog-FieldMask": PLACE_DETAILS_FIELD_MASK },
      },
      "websitePlaceDetails",
    );
    if (!result.ok) {
      res.status(result.status === 404 ? 404 : 502).json({ ok: false, error: "maps unavailable" });
      return;
    }
    res.status(200).json({ ok: true, place: parsePlaceDetails(result.json, body.placeId) });
  },
);
