import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import actions from 'ee/projects/settings_merge_request_approvals/store/actions';
import mutationTypes from 'ee/projects/settings_merge_request_approvals/store/mutation_types';
import createState from 'ee/projects/settings_merge_request_approvals/store/state';
import { TEST_HOST } from 'spec/test_constants';
import testAction from 'spec/helpers/vuex_action_helper';

describe('Approvals store actions', () => {
  const dummyApprovalsUrl = `${TEST_HOST}/approvals`;
  const dummyApproversUrl = `${TEST_HOST}/approvers`;
  const projectId = `8`;
  const dummyUrlSettings = {
    approvalsApiUrl: dummyApprovalsUrl,
    approversApiUrl: dummyApproversUrl,
    projectId,
  };
  const dummySettings = { approvers: [], approver_groups: [], other_setting: true };
  const dummySelectEvent = {
    val: ['3', '4'],
    added: { id: 4, name: 'test subject' },
  };

  let axiosMock;
  let state;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    state = {
      ...createState(),
      ...dummyUrlSettings,
    };
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('requestLoadSettings', () => {
    it('commits REQUEST_UPDATED_SETTINGS', done => {
      testAction(
        actions.requestLoadSettings,
        dummyUrlSettings,
        state,
        [{ type: mutationTypes.REQUEST_LOAD_SETTINGS, payload: dummyUrlSettings }],
        [],
        done,
      );
    });
  });

  describe('receiveLoadSettings', () => {
    it('commits RECEIVE_LOAD_SETTINGS', done => {
      testAction(
        actions.receiveLoadSettings,
        dummySettings,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_SETTINGS, payload: dummySettings }],
        [],
        done,
      );
    });
  });

  describe('updateGroups', () => {
    it('commits UPDATE_APPROVER_GROUPS', done => {
      testAction(
        actions.updateGroups,
        dummySelectEvent,
        state,
        [{ type: mutationTypes.UPDATE_APPROVER_GROUPS, payload: dummySelectEvent }],
        [],
        done,
      );
    });
  });

  describe('updateUsers', () => {
    it('commits UPDATE_APPROVERS', done => {
      testAction(
        actions.updateUsers,
        dummySelectEvent,
        state,
        [{ type: mutationTypes.UPDATE_APPROVERS, payload: dummySelectEvent }],
        [],
        done,
      );
    });
  });

  describe('requestUpdateSettings', () => {
    it('commits REQUEST_UPDATED_SETTINGS', done => {
      testAction(
        actions.requestUpdateSettings,
        null,
        state,
        [{ type: mutationTypes.REQUEST_UPDATED_SETTINGS }],
        [],
        done,
      );
    });
  });

  describe('receiveLoadSettingsError', () => {
    it('commits RECEIVE_LOAD_SETTINGS_ERROR', done => {
      testAction(
        actions.receiveLoadSettingsError,
        null,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_SETTINGS_ERROR }],
        [],
        done,
      );
    });
  });

  describe('receiveUpdateSettingsError', () => {
    it('commits REQUEST_UPDATED_SETTINGS_ERROR', done => {
      testAction(
        actions.receiveUpdateSettingsError,
        null,
        state,
        [{ type: mutationTypes.REQUEST_UPDATED_SETTINGS_ERROR }],
        [],
        done,
      );
    });
  });

  describe('loadSettings', () => {
    let dispatch;
    let approvalEndpointMock;
    beforeEach(() => {
      approvalEndpointMock = axiosMock.onGet(dummyApprovalsUrl);
      dispatch = jasmine.createSpy('dispatch');
    });

    it('dispatches requestLoadSettings and receiveLoadSettings for successful response', done => {
      approvalEndpointMock.replyOnce(() => {
        expect(dispatch.calls.allArgs()).toEqual([['requestLoadSettings', dummyUrlSettings]]);
        dispatch.calls.reset();
        return [200, dummySettings];
      });

      actions
        .loadSettings({ state, dispatch }, dummyUrlSettings)
        .then(() => {
          expect(dispatch.calls.allArgs()).toEqual([['receiveLoadSettings', dummySettings]]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestLoadSettings and receiveLoadSettingsError for error response', done => {
      approvalEndpointMock.replyOnce(() => {
        expect(dispatch.calls.allArgs()).toEqual([['requestLoadSettings', dummyUrlSettings]]);
        dispatch.calls.reset();
        return [500, ''];
      });

      actions
        .loadSettings({ state, dispatch }, dummyUrlSettings)
        .then(() => done.fail('Expected Ajax call to fail!'))
        .catch(() => {
          expect(dispatch.calls.allArgs()).toEqual([['receiveLoadSettingsError']]);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('saveSettings', () => {
    let dispatch;
    let approvalEndpointMock;
    let approverEndpointMock;
    beforeEach(() => {
      approvalEndpointMock = axiosMock.onPost(dummyApprovalsUrl);
      approverEndpointMock = axiosMock.onPut(dummyApproversUrl);
      dispatch = jasmine.createSpy('dispatch');
      state = {
        ...state,
        settings: dummySettings,
      };
    });

    it('dispatches requestUpdateSettings and receiveLoadSettings for successful response', done => {
      approvalEndpointMock.replyOnce(() => {
        expect(dispatch.calls.allArgs()).toEqual([['requestUpdateSettings']]);
        dispatch.calls.reset();
        return [200, dummySettings];
      });

      approverEndpointMock.replyOnce(() => {
        return [200, dummySettings];
      });

      actions
        .saveSettings({ state, dispatch })
        .then(() => {
          expect(dispatch.calls.allArgs()).toEqual([['receiveLoadSettings', dummySettings]]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestUpdateSettings and receiveLoadSettings for error response on updating settings', done => {
      approvalEndpointMock.replyOnce(() => {
        expect(dispatch.calls.allArgs()).toEqual([['requestUpdateSettings']]);
        dispatch.calls.reset();
        return [500, ''];
      });

      actions
        .saveSettings({ state, dispatch })
        .then(() => done.fail('Expected Ajax call to fail!'))
        .catch(() => {
          expect(dispatch.calls.allArgs()).toEqual([['receiveUpdateSettingsError']]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestUpdateSettings and receiveLoadSettings for error response on updating approvers', done => {
      approvalEndpointMock.replyOnce(() => {
        expect(dispatch.calls.allArgs()).toEqual([['requestUpdateSettings']]);
        dispatch.calls.reset();
        return [200, dummySettings];
      });

      approverEndpointMock.replyOnce(() => {
        return [500, ''];
      });

      actions
        .saveSettings({ state, dispatch })
        .then(() => done.fail('Expected Ajax call to fail!'))
        .catch(() => {
          expect(dispatch.calls.allArgs()).toEqual([['receiveUpdateSettingsError']]);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
