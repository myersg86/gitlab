import axios from '~/lib/utils/axios_utils';
import types from './mutation_types';

export default {
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
        dispatch('receiveLoadSettings', res.data);
      });
  },
};
