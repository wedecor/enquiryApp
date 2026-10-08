import { logger } from "firebase-functions/v2";
import * as nodemailer from "nodemailer";
import type { Transporter } from "nodemailer";

/**
 * SMTP configuration:
 * - SMTP_HOST / SMTP_PORT / SMTP_USER / SMTP_FROM_EMAIL: plain env vars loaded by the Firebase CLI
 *   from functions/.env (see functions/.env.example). `functions.env` in firebase.json is ignored.
 * - SMTP_PASS: Secret Manager (`firebase functions:secrets:set SMTP_PASS`).
 */

/** Secret names bound to functions that send email (see inviteUser). */
export const SMTP_SECRET_NAMES = ["SMTP_PASS"] as const;

function readSmtpConfig() {
  return {
    host: process.env.SMTP_HOST || "smtp.gmail.com",
    port: parseInt(process.env.SMTP_PORT || "587", 10),
    user: process.env.SMTP_USER || "",
    pass: process.env.SMTP_PASS || "",
    fromEmail: process.env.SMTP_FROM_EMAIL || process.env.SMTP_USER || "",
  };
}

/** Returns a transporter when SMTP_USER and SMTP_PASS are configured; otherwise null. */
export function createEmailTransporter(): Transporter | null {
  const { host, port, user, pass } = readSmtpConfig();

  if (!user || !pass) {
    logger.warn(
      "SMTP not configured — invitation emails will be skipped. " +
        "Set SMTP_USER in functions/.env and SMTP_PASS in Secret Manager, then redeploy functions."
    );
    return null;
  }

  logger.info("Using SMTP configuration from environment");
  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
  });
}

/** From header for outbound mail. */
export function getSmtpFromAddress(): string {
  const { fromEmail } = readSmtpConfig();
  if (fromEmail) {
    return `"WeDecor Events" <${fromEmail}>`;
  }
  return '"WeDecor Events" <noreply@wedecor.local>';
}
