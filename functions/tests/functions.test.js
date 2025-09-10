import { approveUser } from '../src/index';
describe('approveUser callable', () => {
    it('rejects unauthenticated', async () => {
        await expect(approveUser({}, { auth: null })).rejects.toBeTruthy();
    });
    it('rejects non-admin caller', async () => {
        const context = { auth: { token: { role: 'staff' } } };
        await expect(approveUser({ uid: 'x', role: 'partner' }, context)).rejects.toBeTruthy();
    });
});
