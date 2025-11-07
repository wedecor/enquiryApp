const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { getFirestore, connectFirestoreEmulator, doc, setDoc, updateDoc, getDoc } = require('firebase/firestore');
const { initializeApp } = require('firebase/app');
const fs = require('fs');

const PROJECT_ID = 'demo-we-decor';
let testEnv;

function appFor(uid, role) {
  const app = initializeApp({ projectId: PROJECT_ID }, `${uid || 'anon'}-${role || 'none'}`);
  const db = connectFirestoreEmulator(getFirestore(app), '127.0.0.1', 8080);
  return { app, db, uid, role };
}

function authedContext(uid, role) {
  return testEnv.authenticatedContext(uid, { role });
}

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
  });

  // Seed via admin (rules bypass)
  const adminCtx = testEnv.unauthenticatedContext();
  const adminApp = adminCtx.app;
  const adminDb = connectFirestoreEmulator(getFirestore(adminApp), '127.0.0.1', 8080);

  await setDoc(doc(adminDb, 'users/admin1'), { role: 'admin', name: 'Admin' });
  await setDoc(doc(adminDb, 'users/staff1'), { role: 'staff', name: 'Staff 1' });
  await setDoc(doc(adminDb, 'users/staff2'), { role: 'staff', name: 'Staff 2' });

  await setDoc(doc(adminDb, 'enquiries/E1'), {
    customerName: 'Alice',
    customerNameLower: 'alice',
    status: 'new',
    assignee: 'staff1',
    createdBy: 'admin1',
    createdByName: 'Admin',
    createdAt: new Date(),
    updatedAt: new Date(),
  });
});

afterAll(async () => { await testEnv.cleanup(); });

test('staff assignee can update ONLY status fields', async () => {
  const ctx = await authedContext('staff1', 'staff');
  const db = ctx.firestore();
  await assertSucceeds(updateDoc(doc(db, 'enquiries/E1'), {
    status: 'contacted',
    statusUpdatedBy: 'staff1',
    statusUpdatedAt: new Date(),
    updatedAt: new Date(),
  }));
  await assertFails(updateDoc(doc(db, 'enquiries/E1'), { notes: 'should fail' }));
});

test('non-assignee staff cannot update status', async () => {
  const ctx = await authedContext('staff2', 'staff');
  const db = ctx.firestore();
  await assertFails(updateDoc(doc(db, 'enquiries/E1'), {
    status: 'quoted', statusUpdatedBy: 'staff2', statusUpdatedAt: new Date(), updatedAt: new Date(),
  }));
});

test('admin can update any field', async () => {
  const ctx = await authedContext('admin1', 'admin');
  const db = ctx.firestore();
  await assertSucceeds(updateDoc(doc(db, 'enquiries/E1'), { notes: 'ok by admin' }));
});

test('all authed users can read enquiries', async () => {
  const ctx = await authedContext('staff2', 'staff');
  const db = ctx.firestore();
  await assertSucceeds(getDoc(doc(db, 'enquiries/E1')));
});
