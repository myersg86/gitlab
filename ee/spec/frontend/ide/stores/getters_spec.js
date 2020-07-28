import * as getters from 'ee/ide/stores/getters';
import { createStore } from 'ee/ide/stores';

describe('EE IDE store getters', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('currentTreeLoaded', () => {
    beforeEach(() => {
      localState.currentProjectId = 'gitlab-org/gitlab';
      localState.currentBranchId = 'master';
    });

    it('returns false if the currentTree does not exist', () => {
      expect(getters.currentTreeLoaded(localState)).toBe(false);
    });

    it('returns false if currentTree is loading', () => {
      localState.trees['gitlab-org/gitlab/master'] = { loading: true };

      expect(getters.currentTreeLoaded(localState)).toBe(false);
    });

    it('returns true if the currentTree has loaded', () => {
      localState.trees['gitlab-org/gitlab/master'] = { loading: false };

      expect(getters.currentTreeLoaded(localState)).toBe(true);
    });
  });
});
