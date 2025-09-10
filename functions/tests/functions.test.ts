import { approveUser } from '../src/index';

describe('approveUser callable', () => {
  it('exports a function', () => {
    expect(typeof approveUser).toBe('function');
  });
});
