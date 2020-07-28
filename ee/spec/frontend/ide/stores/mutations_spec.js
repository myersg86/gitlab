import mutations from 'ee/ide/stores/mutations';
import state from 'ee/ide/stores/state';

describe('EE IDE store mutations', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('SET_CONFIG', () => {
    it('sets IDE config', () => {
      mutations.SET_CONFIG(localState, {
        test: 'test',
      });

      expect(localState.config).toEqual({ test: 'test' });
    });
  });
});
