import { logger } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { getFirestore } from "firebase-admin/firestore";
import { requireActiveCaller } from "./auth";
import {
  buildAutocompleteBody,
  isValidPlaceId,
  isValidSessionToken,
  normalizeAutocompleteInput,
  parseAutocompleteResponse,
  parsePlaceDetails,
  PLACE_DETAILS_FIELD_MASK,
  PlaceDetailsResult,
  PlaceSuggestion,
} from "./placesLogic";

/**
 * Google Maps Platform key restricted to "Places API (New)". Lives in Secret Manager
 * (`firebase functions:secrets:set GOOGLE_MAPS_API_KEY`) so it never ships in the app.
 */
const GOOGLE_MAPS_API_KEY = defineSecret("GOOGLE_MAPS_API_KEY");

const PLACES_BASE = "https://places.googleapis.com/v1";
const REQUEST_TIMEOUT_MS = 5000;

type PlacesAutocompleteRequest = {
  input: string;
  sessionToken: string;
  /** Sent when the enquiry form opens: starts this function so the first real search is fast. No Google call. */
  warmUp?: boolean;
};
type PlacesAutocompleteResponse = { suggestions: PlaceSuggestion[] };
type PlaceDetailsRequest = { placeId: string; sessionToken: string };

/** Active-user checks remembered per instance, so typing doesn't re-read the user doc. */
const ACTIVE_USER_TTL_MS = 5 * 60 * 1000;
const activeUserUntil = new Map<string, number>();

async function requireActiveUser(uid: string | undefined): Promise<string> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be signed in to search locations");
  }
  const cachedUntil = activeUserUntil.get(uid);
  if (cachedUntil && cachedUntil > Date.now()) return uid;

  try {
    await requireActiveCaller(getFirestore(), uid, {
      unauthenticatedMessage: "Must be signed in to search locations",
    });
  } catch (err) {
    activeUserUntil.delete(uid);
    throw err;
  }
  activeUserUntil.set(uid, Date.now() + ACTIVE_USER_TTL_MS);
  return uid;
}

function apiKeyOrThrow(): string {
  let key = "";
  try {
    key = GOOGLE_MAPS_API_KEY.value();
  } catch {
    key = "";
  }
  if (!key) {
    throw new HttpsError("failed-precondition", "Maps search isn't set up yet");
  }
  return key;
}

/** fetch with a hard timeout; maps network failures to friendly HttpsErrors. */
async function placesFetch(url: string, init: RequestInit, op: string): Promise<unknown> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  let response: Response;
  try {
    response = await fetch(url, { ...init, signal: controller.signal });
  } catch (e) {
    const aborted = (e as { name?: string })?.name === "AbortError";
    logger.warn(`${op}: request failed`, { aborted });
    throw new HttpsError(
      "unavailable",
      aborted ? "Maps search timed out. Try again." : "Couldn't reach Maps search. Try again."
    );
  } finally {
    clearTimeout(timer);
  }

  if (!response.ok) {
    // Status only — the body can echo request details; the key is in a header, never logged.
    logger.warn(`${op}: Places API error`, { status: response.status });
    if (response.status === 400) {
      throw new HttpsError("invalid-argument", "Maps search couldn't use that request");
    }
    if (response.status === 404) {
      throw new HttpsError("not-found", "That place could not be found");
    }
    if (response.status === 429) {
      throw new HttpsError("resource-exhausted", "Maps search is busy. Try again in a minute.");
    }
    if (response.status === 401 || response.status === 403) {
      throw new HttpsError("failed-precondition", "Maps search isn't set up correctly");
    }
    throw new HttpsError("unavailable", "Maps search is unavailable right now");
  }

  try {
    return await response.json();
  } catch {
    logger.warn(`${op}: invalid JSON from Places API`, { status: response.status });
    throw new HttpsError("internal", "Maps search returned an unexpected response");
  }
}

/**
 * Venue type-ahead for the enquiry Location field. Billed as Autocomplete (New) session
 * usage; the session ends with the matching `placeDetails` call.
 */
export const placesAutocomplete = onCall<PlacesAutocompleteRequest, Promise<PlacesAutocompleteResponse>>(
  {
    cors: true,
    region: "asia-south1",
    enforceAppCheck: false,
    secrets: [GOOGLE_MAPS_API_KEY],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Must be signed in to search locations");
    }
    const data = (request.data ?? {}) as Partial<PlacesAutocompleteRequest>;
    if (data.warmUp === true) return { suggestions: [] };
    const input = normalizeAutocompleteInput(data.input);
    if (!input) {
      throw new HttpsError("invalid-argument", "input must be 2 to 100 characters");
    }
    if (!isValidSessionToken(data.sessionToken)) {
      throw new HttpsError("invalid-argument", "sessionToken is required");
    }
    const key = apiKeyOrThrow();

    // The user check comes first: Google bills every request, so a signed-in but
    // inactive (or unknown) account must never reach it. The check is cached per
    // instance (ACTIVE_USER_TTL_MS), so typing costs one user read at most.
    const uid = await requireActiveUser(request.auth.uid);
    const json = await placesFetch(
      `${PLACES_BASE}/places:autocomplete`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Goog-Api-Key": key },
        body: JSON.stringify(buildAutocompleteBody(input, data.sessionToken)),
      },
      "placesAutocomplete"
    );
    const suggestions = parseAutocompleteResponse(json);
    logger.info("placesAutocomplete completed", { by: uid, count: suggestions.length });
    return { suggestions };
  }
);

/**
 * Address + coordinates for a picked suggestion. Field mask is Essentials-only
 * (no displayName) to keep each call on the cheapest Place Details SKU.
 */
export const placeDetails = onCall<PlaceDetailsRequest, Promise<PlaceDetailsResult>>(
  {
    cors: true,
    region: "asia-south1",
    enforceAppCheck: false,
    secrets: [GOOGLE_MAPS_API_KEY],
  },
  async (request) => {
    const uid = await requireActiveUser(request.auth?.uid);
    const data = (request.data ?? {}) as Partial<PlaceDetailsRequest>;
    if (!isValidPlaceId(data.placeId)) {
      throw new HttpsError("invalid-argument", "placeId is required");
    }
    if (!isValidSessionToken(data.sessionToken)) {
      throw new HttpsError("invalid-argument", "sessionToken is required");
    }
    const key = apiKeyOrThrow();

    const url =
      `${PLACES_BASE}/places/${encodeURIComponent(data.placeId)}` +
      `?sessionToken=${encodeURIComponent(data.sessionToken)}`;
    const json = await placesFetch(
      url,
      {
        method: "GET",
        headers: { "X-Goog-Api-Key": key, "X-Goog-FieldMask": PLACE_DETAILS_FIELD_MASK },
      },
      "placeDetails"
    );
    const result = parsePlaceDetails(json, data.placeId);
    logger.info("placeDetails completed", {
      by: uid,
      hasArea: result.area !== null,
      isArea: result.isArea,
      hasLocation: result.lat !== null,
    });
    return result;
  }
);
