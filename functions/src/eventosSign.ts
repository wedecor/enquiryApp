/**
 * HMAC signing for the EventOS Enquiries feed (M5-01).
 * Shared test vector with EventOS:
 *   secret `test_secret`, timestamp `1700000000`, body `{"a":1}`
 *   → v1=f5a131af104d1c1624551668e089377efc5317cc715258c10d2c12d6cf67cb4e
 */

import { createHmac } from "crypto";

/** `v1=<lowercase hex HMAC-SHA256(secret, timestamp + "." + rawBody)>` */
export function signEventOSFeedBody(
  secret: string,
  timestamp: string,
  rawBody: string | Buffer,
): string {
  const digest = createHmac("sha256", secret)
    .update(timestamp)
    .update(".")
    .update(rawBody)
    .digest("hex");
  return `v1=${digest}`;
}
