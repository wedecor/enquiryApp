/**
 * Pure helpers for the Google Places (New) callables in places.ts — no Firebase or
 * network code here so they can be exercised from a plain Node script.
 */

/** Bangalore city centre; autocomplete results are biased (not restricted) to 50 km around it. */
export const BANGALORE_CENTER = { latitude: 12.9716, longitude: 77.5946 } as const;
export const BIAS_RADIUS_METERS = 50000;
export const MAX_SUGGESTIONS = 5;
export const MIN_INPUT_LENGTH = 2;
export const MAX_INPUT_LENGTH = 100;

/**
 * Essentials-SKU fields only (`types` is Essentials; `primaryType` and `displayName`
 * are Pro — requesting them would bill every details call at the Pro rate, so the
 * name comes from the autocomplete suggestion's `mainText` instead).
 */
export const PLACE_DETAILS_FIELD_MASK = "id,formattedAddress,location,addressComponents,types";

export type PlaceSuggestion = {
  placeId: string;
  mainText: string;
  secondaryText: string;
};

export type PlaceDetailsResult = {
  placeId: string;
  address: string | null;
  lat: number | null;
  lng: number | null;
  area: string | null;
  city: string | null;
  /** The place is itself an area (e.g. "JP Nagar"), not a venue; `area` is its own name. */
  isArea: boolean;
};

const SESSION_TOKEN_RE = /^[A-Za-z0-9_-]{8,64}$/;
/** Place ids are URL-safe base64-ish strings; reject anything that could alter the URL path. */
const PLACE_ID_RE = /^[A-Za-z0-9_-]{8,512}$/;

export function isValidSessionToken(value: unknown): value is string {
  return typeof value === "string" && SESSION_TOKEN_RE.test(value);
}

export function isValidPlaceId(value: unknown): value is string {
  return typeof value === "string" && PLACE_ID_RE.test(value);
}

/** Trimmed autocomplete input, or null when outside 2..100 characters. */
export function normalizeAutocompleteInput(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (trimmed.length < MIN_INPUT_LENGTH || trimmed.length > MAX_INPUT_LENGTH) return null;
  return trimmed;
}

/** Request body for POST https://places.googleapis.com/v1/places:autocomplete. */
export function buildAutocompleteBody(input: string, sessionToken: string) {
  return {
    input,
    sessionToken,
    includedRegionCodes: ["in"],
    languageCode: "en",
    locationBias: {
      circle: {
        center: { latitude: BANGALORE_CENTER.latitude, longitude: BANGALORE_CENTER.longitude },
        radius: BIAS_RADIUS_METERS,
      },
    },
  };
}

function str(raw: unknown): string {
  return typeof raw === "string" ? raw.trim() : "";
}

function textOf(raw: unknown): string {
  if (raw && typeof raw === "object") return str((raw as { text?: unknown }).text);
  return "";
}

/**
 * Parses the autocomplete response into at most [MAX_SUGGESTIONS] place suggestions.
 * Query predictions (no placeId) and malformed entries are skipped.
 */
export function parseAutocompleteResponse(json: unknown): PlaceSuggestion[] {
  if (!json || typeof json !== "object") return [];
  const raw = (json as { suggestions?: unknown }).suggestions;
  if (!Array.isArray(raw)) return [];
  const out: PlaceSuggestion[] = [];
  for (const entry of raw) {
    if (out.length >= MAX_SUGGESTIONS) break;
    const prediction = entry && typeof entry === "object"
      ? (entry as { placePrediction?: unknown }).placePrediction
      : null;
    if (!prediction || typeof prediction !== "object") continue;
    const p = prediction as {
      placeId?: unknown;
      text?: unknown;
      structuredFormat?: { mainText?: unknown; secondaryText?: unknown };
    };
    const placeId = str(p.placeId);
    if (!placeId) continue;
    const mainText = textOf(p.structuredFormat?.mainText) || textOf(p.text);
    if (!mainText) continue;
    out.push({ placeId, mainText, secondaryText: textOf(p.structuredFormat?.secondaryText) });
  }
  return out;
}

type AddressComponent = { longText?: unknown; shortText?: unknown; types?: unknown };

function componentText(components: AddressComponent[], type: string): string | null {
  for (const c of components) {
    if (Array.isArray(c.types) && c.types.includes(type)) {
      const text = str(c.longText) || str(c.shortText);
      if (text) return text;
    }
  }
  return null;
}

const AREA_TYPES = ["sublocality_level_1", "sublocality", "neighborhood", "sublocality_level_2"];

/**
 * Place types that make a picked place an area rather than a venue, most specific
 * first (so "Koramangala 5th Block" — sublocality_level_2 — is matched before its
 * parent sublocality_level_1).
 */
const PLACE_AREA_TYPES = [
  "neighborhood",
  "sublocality_level_3",
  "sublocality_level_2",
  "sublocality_level_1",
  "sublocality",
  "locality",
  "administrative_area_level_3",
];

/** Types that mean the place is a business / landmark even if it is also political. */
const VENUE_TYPES = ["establishment", "point_of_interest", "premise", "street_address", "route"];

/**
 * City / state / country names that don't say where in Bangalore an event is.
 * Mirrors `vagueLocationNames` in lib/features/enquiries/domain/enquiry_location.dart
 * and `vagueLocationRegex` in firestore.rules.
 */
export const VAGUE_LOCATION_NAMES = [
  "bangalore",
  "bengaluru",
  "banglore",
  "bangaluru",
  "blr",
  "bangalore city",
  "bengaluru city",
  "bangalore urban",
  "bengaluru urban",
  "karnataka",
  "india",
  "bangalore karnataka",
  "bengaluru karnataka",
];

/** Same rule as the Dart `isVagueLocation`: empty, punctuation only, or a city name. */
export function isVagueLocation(text: string | null | undefined): boolean {
  const normalized = (text ?? "")
    .toLowerCase()
    .replace(/[\s\p{Z}\p{P}\p{S}]+/gu, " ")
    .trim();
  return normalized === "" || VAGUE_LOCATION_NAMES.includes(normalized);
}

function finiteOrNull(raw: unknown): number | null {
  return typeof raw === "number" && Number.isFinite(raw) ? raw : null;
}

function stringTypes(raw: unknown): string[] {
  return Array.isArray(raw) ? raw.filter((t): t is string => typeof t === "string") : [];
}

/**
 * The area type the place itself has (e.g. "sublocality_level_1" for "JP Nagar"), or
 * null when it is a venue / address / anything else.
 */
export function placeAreaType(types: string[]): string | null {
  if (types.some((t) => VENUE_TYPES.includes(t))) return null;
  return PLACE_AREA_TYPES.find((t) => types.includes(t)) ?? null;
}

/**
 * Parses a Place Details (New) response requested with [PLACE_DETAILS_FIELD_MASK].
 *
 * Venue: area = first of sublocality_level_1 / sublocality / neighborhood /
 * sublocality_level_2. Area pick (the place's own types are an area type): area = the
 * component carrying that type, i.e. the area's own name ("JP Nagar", "Whitefield").
 * A bare city / state / country ("Bengaluru") is never reported as the area.
 * city = locality, else administrative_area_level_2 (for an area that is itself a
 * locality, the district instead of repeating the area).
 */
export function parsePlaceDetails(json: unknown, fallbackPlaceId: string): PlaceDetailsResult {
  const data = (json && typeof json === "object" ? json : {}) as {
    id?: unknown;
    formattedAddress?: unknown;
    location?: { latitude?: unknown; longitude?: unknown };
    addressComponents?: unknown;
    types?: unknown;
  };
  const components: AddressComponent[] = Array.isArray(data.addressComponents)
    ? data.addressComponents.filter((c): c is AddressComponent => !!c && typeof c === "object")
    : [];

  let area: string | null = null;
  const ownAreaType = placeAreaType(stringTypes(data.types));
  if (ownAreaType) {
    area = componentText(components, ownAreaType);
  }
  if (!area) {
    for (const type of AREA_TYPES) {
      area = componentText(components, type);
      if (area) break;
    }
  }
  if (isVagueLocation(area)) area = null;
  const isArea = ownAreaType !== null && area !== null;

  let city =
    componentText(components, "locality") ?? componentText(components, "administrative_area_level_2");
  if (isArea && city !== null && area !== null && city.toLowerCase() === area.toLowerCase()) {
    city = componentText(components, "administrative_area_level_2") ?? city;
  }
  const lat = finiteOrNull(data.location?.latitude);
  const lng = finiteOrNull(data.location?.longitude);
  return {
    placeId: str(data.id) || fallbackPlaceId,
    address: str(data.formattedAddress) || null,
    // Only report a position when both coordinates are present.
    lat: lat !== null && lng !== null ? lat : null,
    lng: lat !== null && lng !== null ? lng : null,
    area,
    city,
    isArea,
  };
}
