/**
 * M5-01 — enquiries/{id}/private/eventosSync is Admin SDK only.
 * Clients (admin, staff, unauthenticated) cannot read or write.
 */
const {
  initializeTestEnvironment,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

describe('EventOS private sync bookkeeping rules (M5-01)', () => {
  let testEnv;
  const PROJECT_ID = `test-eventos-private-${Date.now()}`;
  const ADMIN_UID = 'admin-eventos-1';
  const STAFF_UID = 'staff-eventos-1';
  const ENQUIRY_ID = 'enquiry-eventos-1';

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
        host: 'localhost',
        port: 8080,
      },
    });
  });

  afterAll(async () => {
    if (testEnv) await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('users').doc(ADMIN_UID).set({
        role: 'admin',
        isActive: true,
        active: true,
      });
      await db.collection('users').doc(STAFF_UID).set({
        role: 'staff',
        isActive: true,
        active: true,
      });
      await db.collection('enquiries').doc(ENQUIRY_ID).set({
        customerName: 'Test',
        assignedTo: STAFF_UID,
        statusValue: 'approved',
      });
      await db
        .collection('enquiries')
        .doc(ENQUIRY_ID)
        .collection('private')
        .doc('eventosSync')
        .set({ lastHash: 'abc', lastStatus: 'approved' });
    });
  });

  function syncRef(uid, claims) {
    return testEnv
      .authenticatedContext(uid, claims)
      .firestore()
      .collection('enquiries')
      .doc(ENQUIRY_ID)
      .collection('private')
      .doc('eventosSync');
  }

  it('denies admin read/write of private/eventosSync', async () => {
    const ref = syncRef(ADMIN_UID, { role: 'admin' });
    await assertFails(ref.get());
    await assertFails(ref.set({ lastHash: 'x' }));
    await assertFails(ref.update({ lastHash: 'y' }));
    await assertFails(ref.delete());
  });

  it('denies staff read/write of private/eventosSync', async () => {
    const ref = syncRef(STAFF_UID, { role: 'staff' });
    await assertFails(ref.get());
    await assertFails(ref.set({ lastHash: 'x' }));
  });

  it('denies unauthenticated read/write of private/eventosSync', async () => {
    const ref = testEnv
      .unauthenticatedContext()
      .firestore()
      .collection('enquiries')
      .doc(ENQUIRY_ID)
      .collection('private')
      .doc('eventosSync');
    await assertFails(ref.get());
    await assertFails(ref.set({ lastHash: 'x' }));
  });
});
