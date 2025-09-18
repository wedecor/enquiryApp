import 'dotenv/config';

export const env = {
  FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID || 'wedecorenquries',
  GOOGLE_APPLICATION_CREDENTIALS: process.env.GOOGLE_APPLICATION_CREDENTIALS || '',
  SENTRY_DSN: process.env.SENTRY_DSN || '',
  MAIL_HOST: process.env.MAIL_HOST || '',
  MAIL_PORT: parseInt(process.env.MAIL_PORT || '587'),
  MAIL_USER: process.env.MAIL_USER || '',
  MAIL_PASS: process.env.MAIL_PASS || '',
  SMTP_FROM_EMAIL: process.env.SMTP_FROM_EMAIL || '',
  NODE_ENV: process.env.NODE_ENV || 'development',
  LOG_LEVEL: process.env.LOG_LEVEL || 'info',
};
