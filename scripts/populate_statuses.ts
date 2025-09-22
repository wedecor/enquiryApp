import * as fs from 'fs';
import * as pathMod from 'path';
import admin from 'firebase-admin';

type Status = { 
  id: string; 
  label: string; 
  order: number; 
  active: boolean; 
  createdAt?: any; 
  updatedAt?: any; 
};

function arg(k: string, d?: string) {
  const v = process.argv.find(a => a.startsWith(`--${k}=`));
  return v ? v.split('=')[1] : d;
}

const DRY_RUN = !!process.env.DRY_RUN;
const CONFIRM_PROD = process.env.CONFIRM_PROD === 'YES';
const projectId = arg('project', process.env.GCLOUD_PROJECT || 'wedecorenquries')!;
const collectionPath = arg('path', 'dropdowns/statuses/items')!;
const creds = process.env.GOOGLE_APPLICATION_CREDENTIALS;

const DESIRED = [
  { id: 'new', label: 'New' },
  { id: 'in_talks', label: 'In Talks' },
  { id: 'confirmed', label: 'Confirmed' },
  { id: 'completed', label: 'Completed' },
  { id: 'cancelled', label: 'Cancelled' },
  { id: 'not_interested', label: 'Not Interested' },
  { id: 'quotation_sent', label: 'Quotation Sent' },
];

if (!creds) { 
  console.error('GOOGLE_APPLICATION_CREDENTIALS not set'); 
  process.exit(1); 
}

admin.initializeApp({ 
  credential: admin.credential.applicationDefault(), 
  projectId 
});
const db = admin.firestore();

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    out.push(arr.slice(i, i + size));
  }
  return out;
}

(async () => {
  console.log('[Seeder] projectId:', projectId);
  console.log('[Seeder] path:', collectionPath);
  console.log('[Seeder] creds:', creds);
  console.log('[Seeder] DRY_RUN:', DRY_RUN, 'CONFIRM_PROD:', CONFIRM_PROD);

  if (!DRY_RUN && !CONFIRM_PROD) {
    console.error('Refusing to modify production without CONFIRM_PROD=YES'); 
    process.exit(1);
  }

  // Read existing
  const snap = await db.collection(collectionPath).get();
  const existingDocs = snap.docs;
  const existingIds = existingDocs.map(d => d.id);
  console.log('[Seeder] Existing count:', existingIds.length, 'IDs:', existingIds);

  // Backup
  const backupsDir = pathMod.join(process.cwd(), 'backups');
  if (!fs.existsSync(backupsDir)) {
    fs.mkdirSync(backupsDir, { recursive: true });
  }
  const ts = new Date().toISOString().replace(/[:-]/g, '').replace(/\..+/, '');
  const backupFile = pathMod.join(backupsDir, `statuses-${ts}.json`);
  const backupPayload = existingDocs.map(d => ({ id: d.id, ...d.data() }));
  fs.writeFileSync(backupFile, JSON.stringify(backupPayload, null, 2));
  console.log('[Seeder] Backup saved:', backupFile);

  // Plan
  const desiredIds = DESIRED.map(x => x.id);
  const toDelete = existingIds.filter(id => !desiredIds.includes(id));
  const toUpsert = DESIRED.map((x, i) => ({
    ...x,
    order: i + 1,
    active: true,
  }));

  console.log('[Seeder] To upsert:', toUpsert.map(d => d.id));
  console.log('[Seeder] To delete:', toDelete);

  if (DRY_RUN) {
    console.log('[Seeder] DRY RUN complete. No writes performed.'); 
    process.exit(0);
  }

  // Batched writes
  const batched: admin.firestore.WriteBatch[] = [];
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Upsert operations
  const upsertChunks = chunk(toUpsert, 400);
  for (const uc of upsertChunks) {
    const b = db.batch();
    for (const s of uc) {
      const ref = db.collection(collectionPath).doc(s.id);
      const existing = snap.docs.find(d => d.id === s.id)?.data() as Partial<Status> | undefined;
      b.set(ref, {
        id: s.id,
        label: s.label,
        order: s.order,
        active: true,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      }, { merge: true });
    }
    batched.push(b);
  }

  // Delete operations
  const delChunks = chunk(toDelete, 400);
  for (const dc of delChunks) {
    const b = db.batch();
    for (const id of dc) {
      const ref = db.collection(collectionPath).doc(id);
      b.delete(ref);
    }
    batched.push(b);
  }

  // Execute batches
  for (let i = 0; i < batched.length; i++) {
    const b = batched[i];
    await b.commit();
    console.log(`[Seeder] Batch ${i + 1}/${batched.length} committed`);
  }

  console.log('[Seeder] DONE. Upserts:', toUpsert.length, 'Deletions:', toDelete.length, 'Backup:', backupFile);

  // Verify
  const verify = await db.collection(collectionPath).get();
  const finalIds = verify.docs.map(d => d.id).sort();
  console.log('[Seeder] Final IDs:', finalIds);
  
  // Check if all desired statuses are present
  const missing = desiredIds.filter(id => !finalIds.includes(id));
  const extra = finalIds.filter(id => !desiredIds.includes(id));
  
  if (missing.length > 0) {
    console.error('[Seeder] WARNING: Missing statuses:', missing);
  }
  if (extra.length > 0) {
    console.error('[Seeder] WARNING: Extra statuses:', extra);
  }
  
  if (missing.length === 0 && extra.length === 0) {
    console.log('[Seeder] SUCCESS: All statuses match expected state');
  }
})().catch(e => {
  console.error('[Seeder] ERROR:', e);
  process.exit(1);
});