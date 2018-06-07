import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import actions, {
  formatSettings,
} from 'ee/projects/settings_merge_request_approvals/store/actions';
import mutationTypes from 'ee/projects/settings_merge_request_approvals/store/mutation_types';
import createState from 'ee/projects/settings_merge_request_approvals/store/state';
import { TEST_HOST } from 'spec/test_constants';
import testAction from 'spec/helpers/vuex_action_helper';
import { generateDummyGroup, generateDummyUser } from '../dummy_settings';

describe('Approvals store actions', () => {
  const dummyApprovalsUrl = `${TEST_HOST}/approvals`;
  const dummyApproversUrl = `${TEST_HOST}/approvers`;
  const projectId = '8';
  const dummyUrlSettings = {
    approvalsApiUrl: dummyApprovalsUrl,
    approversApiUrl: dummyApproversUrl,
    projectId,
  };
  const dummyAPIResponse = {
    approvers: [{ user: generateDummyUser(7) }],
    approver_groups: [{ group: generateDummyGroup(9) }],
    other_setting: true,
  };

  const dummySettings = formatSettings(dummyAPIResponse);

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
        dummyAPIResponse,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_SETTINGS, payload: dummyAPIResponse }],
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
    it('commits RECEIVE_UPDATED_SETTINGS_ERROR', done => {
      testAction(
        actions.receiveUpdateSettingsError,
        null,
        state,
        [{ type: mutationTypes.RECEIVE_UPDATED_SETTINGS_ERROR }],
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
        return [200, dummyAPIResponse];
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
        return [200, dummyAPIResponse];
      });

      approverEndpointMock.replyOnce(() => [200, dummyAPIResponse]);

      actions
        .saveSettings({ state, dispatch })
        .then(() => {
          expect(dispatch.calls.allArgs()).toEqual([['receiveLoadSettings', dummySettings]]);
        })
        .then(done)
        .catch(done.fail);
    });

    it('request to the /approvals api should not contain users/groups', done => {
      approvalEndpointMock.replyOnce(req => {
        const requestObject = JSON.parse(req.data);

        expect(Object.keys(requestObject)).toContain('other_setting');
        expect(Object.keys(requestObject)).not.toContain('approvers');
        expect(Object.keys(requestObject)).not.toContain('approver_groups');

        return [200, dummyAPIResponse];
      });

      approverEndpointMock.replyOnce(() => [200, dummyAPIResponse]);

      actions
        .saveSettings({ state, dispatch })
        .then(done)
        .catch(done.fail);
    });

    it('request to the /approvers api should only contain user and group ids', done => {
      approvalEndpointMock.replyOnce(() => [200, dummyAPIResponse]);

      approverEndpointMock.replyOnce(req => {
        const requestObject = JSON.parse(req.data);

        expect(Object.keys(requestObject)).not.toContain('other_setting');
        expect(Object.keys(requestObject)).not.toContain('approvers');
        expect(Object.keys(requestObject)).not.toContain('approver_groups');
        expect(Object.keys(requestObject)).toContain('approver_ids');
        expect(Object.keys(requestObject)).toContain('approver_group_ids');
        expect(requestObject.approver_ids.length).toBe(1);
        expect(requestObject.approver_ids[0]).toBe(7);
        expect(requestObject.approver_group_ids.length).toBe(1);
        expect(requestObject.approver_group_ids[0]).toBe(9);

        return [200, dummyAPIResponse];
      });

      actions
        .saveSettings({ state, dispatch })
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
        return [200, dummyAPIResponse];
      });

      approverEndpointMock.replyOnce(() => [500, '']);

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
