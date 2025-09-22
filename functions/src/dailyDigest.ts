import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';

try { admin.initializeApp(); } catch {}
const db = admin.firestore();

export const dailyDigest = onSchedule(
  { schedule: '0 9 * * *', timeZone: 'Asia/Kolkata' },
  async () => {
    const since = new Date();
    since.setDate(since.getDate() - 1);
    const qs = await db.collection('enquiries').where('createdAt', '>=', since).get();
    const counts: Record<string, number> = {};
    qs.forEach((d) => {
      const s = (d.get('status') as string) || 'unknown';
      counts[s] = (counts[s] || 0) + 1;
    });

    await admin.messaging().send({
      topic: 'admins',
      data: { type: 'daily_digest', counts: JSON.stringify(counts) },
      notification: {
        title: 'Daily Enquiries Digest',
        body: Object.entries(counts)
          .map(([k, v]) => `${k}: ${v}`)
          .join(' · '),
      },
    });
  }
);


