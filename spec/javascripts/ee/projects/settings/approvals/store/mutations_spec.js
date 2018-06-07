import store from 'ee/projects/settings_merge_request_approvals/store/index';
import types from 'ee/projects/settings_merge_request_approvals/store/mutation_types';
import createState from 'ee/projects/settings_merge_request_approvals/store/state';
import { TEST_HOST } from 'spec/test_constants';
import { generateDummyGroup, generateDummyUser } from '../dummy_settings';

describe('Approval store mutations', () => {
  const dummyApprovalsUrl = `${TEST_HOST}/approvals`;
  const dummyApproversUrl = `${TEST_HOST}/approvers`;
  const projectId = '8';

  const dummyUrlSettings = {
    approvalsApiUrl: dummyApprovalsUrl,
    approversApiUrl: dummyApproversUrl,
    projectId,
  };

  const dummySettings = {
    approvers: [generateDummyUser(1), generateDummyUser(3), generateDummyUser(2)],
    approver_groups: [generateDummyGroup(1), generateDummyGroup(3), generateDummyGroup(2)],
  };

  beforeEach(() => {
    store.replaceState(createState());
  });

  describe('REQUEST_UPDATED_SETTINGS', () => {
    it('sets isSaving to true', () => {
      expect(store.state.isSaving).toBe(false);

      store.commit(types.REQUEST_UPDATED_SETTINGS);

      expect(store.state.isSaving).toBe(true);
    });
  });

  describe('REQUEST_LOAD_SETTINGS', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
      });
    });

    it('sets API Urls', () => {
      expect(store.state.approvalsApiUrl).toBe(null);
      expect(store.state.approversApiUrl).toBe(null);
      expect(store.state.projectId).toBe(null);

      store.commit(types.REQUEST_LOAD_SETTINGS, dummyUrlSettings);

      expect(store.state.approvalsApiUrl).toBe(dummyApprovalsUrl);
      expect(store.state.approversApiUrl).toBe(dummyApproversUrl);
      expect(store.state.projectId).toBe(projectId);
    });
    it('sets isLoading to true', () => {
      expect(store.state.isLoading).toBe(false);

      store.commit(types.REQUEST_LOAD_SETTINGS, dummyUrlSettings);

      expect(store.state.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_LOAD_SETTINGS', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        settings: null,
        isLoading: true,
        isSaving: true,
      });
    });

    it('sets API Urls', () => {
      expect(store.state.settings).toBe(null);

      store.commit(types.RECEIVE_LOAD_SETTINGS, dummySettings);

      expect(store.state.settings).toBe(dummySettings);
    });
    it('sets isLoading to false', () => {
      expect(store.state.isLoading).toBe(true);

      store.commit(types.RECEIVE_LOAD_SETTINGS, dummySettings);

      expect(store.state.isLoading).toBe(false);
    });
    it('sets isSaving to false', () => {
      expect(store.state.isSaving).toBe(true);

      store.commit(types.RECEIVE_LOAD_SETTINGS, dummySettings);

      expect(store.state.isSaving).toBe(false);
    });
  });

  describe('RECEIVE_LOAD_SETTINGS_ERROR', () => {
    it('sets isLoading to to false', () => {
      store.replaceState({
        ...store.state,
        isLoading: true,
      });

      expect(store.state.isLoading).toBe(true);
      store.commit(types.RECEIVE_LOAD_SETTINGS_ERROR);
      expect(store.state.isLoading).toBe(false);
    });
  });

  describe('RECEIVE_UPDATED_SETTINGS_ERROR', () => {
    it('sets isSaving to to false', () => {
      store.replaceState({
        ...store.state,
        isSaving: true,
      });

      expect(store.state.isSaving).toBe(true);
      store.commit(types.RECEIVE_UPDATED_SETTINGS_ERROR);
      expect(store.state.isSaving).toBe(false);
    });
  });

  const updateMutations = [
    { mutation: 'UPDATE_APPROVERS', field: 'approvers' },
    {
      mutation: 'UPDATE_APPROVER_GROUPS',
      field: 'approver_groups',
    },
  ];

  updateMutations.forEach(({ mutation, field }) => {
    describe(mutation, () => {
      beforeEach(() => {
        const settings = {
          ...dummySettings,
        };

        store.replaceState({
          ...store.state,
          settings,
        });
      });

      it(`deletes entries from the ${field} list`, () => {
        const event = {
          val: ['1', '2'],
        };

        expect(store.state.settings[field].length).toBe(3);

        store.commit(types[mutation], event);

        expect(store.state.settings[field].length).toBe(2);
        expect(store.state.settings[field][0].id).toBe(1);
        expect(store.state.settings[field][1].id).toBe(2);
      });

      it(`adds entries to the ${field} list`, () => {
        const event = {
          added: generateDummyUser(5),
          val: ['1', '3', '2', '5'],
        };

        expect(store.state.settings[field].length).toBe(3);

        store.commit(types[mutation], event);

        expect(store.state.settings[field].length).toBe(4);
        expect(store.state.settings[field][0].id).toBe(1);
        expect(store.state.settings[field][1].id).toBe(3);
        expect(store.state.settings[field][2].id).toBe(2);
        expect(store.state.settings[field][3].id).toBe(5);
      });
    });
  });
});
