import axios from '~/lib/utils/axios_utils';
import types from './mutation_types';

const formatSettings = settings => {
  const approvers = settings.approvers.map(user => user.user);
  const approverGroups = settings.approver_groups.map(group => group.group);
  return { ...settings, approvers, approver_groups: approverGroups };
};

const getApprovalSettings = settings => {
  const newSettings = { ...settings };
  delete newSettings.approvers;
  delete newSettings.approver_groups;
  return newSettings;
};

const getApproverGroupsAndApproversIds = settings => {
  const approvers = settings.approvers.map(user => user.id);
  const approverGroups = settings.approver_groups.map(group => group.id);
  return { approver_ids: approvers, approver_group_ids: approverGroups };
};

export default {
  updateUsers({ commit }, event) {
    commit(types.UPDATE_APPROVERS, event);
  },
  updateGroups({ commit }, event) {
    commit(types.UPDATE_APPROVER_GROUPS, event);
  },
  requestLoadSettings({ commit }, data) {
    commit(types.REQUEST_LOAD_SETTINGS, data);
  },
  receiveLoadSettings({ commit }, settings) {
    commit(types.RECEIVE_LOAD_SETTINGS, settings);
  },
  receiveLoadSettingsError({ commit }) {
    commit(types.RECEIVE_LOAD_SETTINGS_ERROR);
  },
  loadSettings({ dispatch, state }, data) {
    dispatch('requestLoadSettings', data);
    return axios
      .get(state.approvalsApiUrl)
      .catch(error => {
        dispatch('receiveLoadSettingsError');
        throw error;
      })
      .then(res => {
        dispatch('receiveLoadSettings', formatSettings(res.data));
      });
  },
  requestUpdateSettings({ commit }) {
    commit(types.REQUEST_UPDATED_SETTINGS);
  },
  receiveUpdateSettingsError({ commit }) {
    commit(types.REQUEST_UPDATED_SETTINGS_ERROR);
  },
  saveSettings({ dispatch, state }) {
    dispatch('requestUpdateSettings');
    return axios
      // Update Approval Settings
      .post(state.approvalsApiUrl, getApprovalSettings(state.settings))
      // Update Approvers
      .then(() =>
        axios.put(
          state.approversApiUrl,
          getApproverGroupsAndApproversIds(state.settings),
        ),
      )
      .catch(error => {
        dispatch('receiveUpdateSettingsError');
        throw error;
      })
      .then(res => {
        dispatch('receiveLoadSettings', formatSettings(res.data));
      });
  },
};
