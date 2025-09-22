import admin from 'firebase-admin';

function arg(k: string, d?: string) {
  const v = process.argv.find(a => a.startsWith(`--${k}=`));
  return v ? v.split('=')[1] : d;
}

const projectId = arg('project', process.env.GCLOUD_PROJECT || 'wedecorenquries')!;
const path = arg('path', 'dropdowns/statuses/items')!;
const creds = process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (!creds) {
  console.error('GOOGLE_APPLICATION_CREDENTIALS not set'); 
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId });
const db = admin.firestore();

(async () => {
  console.log('[Probe] projectId:', projectId);
  console.log('[Probe] path:', path);
  console.log('[Probe] creds:', creds);
  
  const ref = db.collection(path).doc('__probe__');
  await ref.set({ ok: true, t: Date.now() });
  console.log('WRITE_OK');
  
  await ref.delete();
  console.log('DELETE_OK');
})().catch(e => { 
  console.error(e); 
  process.exit(1); 
});
