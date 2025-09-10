import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { setLogLevel } from 'firebase/firestore';
let testEnv;
beforeAll(async () => {
    setLogLevel('error');
    testEnv = await initializeTestEnvironment({
        projectId: 'wedecorenquiries-test',
        firestore: {
            rules: readFileSync(require('path').resolve(__dirname, '../../firestore.rules'), 'utf8'),
        },
    });
});
afterAll(async () => {
    await testEnv.cleanup();
});
describe('Firestore rules', () => {
    it('pending user denied read', async () => {
        const ctx = testEnv.authenticatedContext('u1', { role: 'pending', isApproved: false });
        const db = ctx.firestore();
        await expect(db.collection('enquiries').get()).rejects.toBeTruthy();
    });
});
