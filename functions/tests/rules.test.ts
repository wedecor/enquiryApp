import { initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';

let testEnv: RulesTestEnvironment;
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;

const maybe = (emulatorHost ? describe : describe.skip);

maybe('Firestore rules', () => {
  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'wedecorenquiries-test',
      firestore: {
        host: (emulatorHost || '').split(':')[0] || '127.0.0.1',
        port: Number((emulatorHost || '').split(':')[1] || 8080),
        rules: readFileSync(require('path').resolve(__dirname, '../../firestore.rules'), 'utf8'),
      },
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  it('pending user denied read', async () => {
    const ctx = testEnv.authenticatedContext('u1', { role: 'pending', isApproved: false });
    const db = ctx.firestore();
    await expect(db.collection('enquiries').get()).rejects.toBeTruthy();
  });
});
