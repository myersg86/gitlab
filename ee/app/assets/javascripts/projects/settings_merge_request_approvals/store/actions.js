import axios from '~/lib/utils/axios_utils';
import types from './mutation_types';

const formatSettings = settings => {
  const approvers = settings.approvers.map(user => user.user);
  console.warn(settings);
  return { ...settings, approvers };
};

export default {
  updateUsers({ commit }, event) {
    commit(types.UPDATE_APPROVERS, event);
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
    const endpoint = state.apiEndpointUrl;
    return axios
      .get(endpoint)
      .catch(error => {
        dispatch('receiveLoadSettingsError');
        throw error;
      })
      .then(res => {
        dispatch('receiveLoadSettings', formatSettings(res.data));
      });
  },
};
