/**
 * Storage rules (storage.rules). Needs the Storage and Firestore emulators:
 *   npx firebase emulators:exec --only firestore,storage --project demo-test "npm run test:storage"
 */
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

describe('Storage rules — enquiry files', () => {
  let testEnv;
  const PROJECT_ID = 'demo-test';
  const ADMIN = 'admin-1';
  const ASSIGNEE = 'staff-assigned';
  const CREATOR = 'staff-creator';
  const image = () => Buffer.from([0x89, 0x50, 0x4e, 0x47]);

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
        host: '127.0.0.1',
        port: 8080,
      },
      storage: {
        rules: readFileSync(resolve(__dirname, '../../storage.rules'), 'utf8'),
        host: '127.0.0.1',
        port: 9199,
      },
    });
  });

  afterAll(async () => {
    if (testEnv) await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.clearStorage();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('users').doc(ADMIN).set({ role: 'admin', isActive: true });
      await db.collection('users').doc(ASSIGNEE).set({ role: 'staff', isActive: true });
      await db.collection('users').doc(CREATOR).set({ role: 'staff', isActive: true });
      // Created by one staff member, assigned to another.
      await db.collection('enquiries').doc('e1').set({ assignedTo: ASSIGNEE, createdBy: CREATOR });
      await context.storage().ref('enquiries/e1/images/a.png').put(image(), { contentType: 'image/png' });
    });
  });

  const ref = (uid, path) => testEnv.authenticatedContext(uid).storage().ref(path);

  test('✅ The assignee can read and upload enquiry images', async () => {
    await assertSucceeds(ref(ASSIGNEE, 'enquiries/e1/images/a.png').getMetadata());
    await assertSucceeds(
      ref(ASSIGNEE, 'enquiries/e1/images/b.png').put(image(), { contentType: 'image/png' })
    );
  });

  test('❌ The creator who is not the assignee cannot read or write the files', async () => {
    await assertFails(ref(CREATOR, 'enquiries/e1/images/a.png').getMetadata());
    await assertFails(
      ref(CREATOR, 'enquiries/e1/images/c.png').put(image(), { contentType: 'image/png' })
    );
    await assertFails(
      ref(CREATOR, 'attachments/e1/quote.pdf').put(image(), { contentType: 'application/pdf' })
    );
  });

  test('✅ Admins are unchanged', async () => {
    await assertSucceeds(ref(ADMIN, 'enquiries/e1/images/a.png').getMetadata());
    await assertSucceeds(ref(ADMIN, 'enquiries/e1/images/a.png').delete());
  });
});
