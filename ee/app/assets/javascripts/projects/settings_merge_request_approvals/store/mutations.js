import types from './mutation_types';

export default {
  [types.RECEIVE_LOAD_SETTINGS](state, settings) {
    Object.assign(state, {
      settings,
      isLoading: false,
    });
  },
  [types.RECEIVE_LOAD_SETTINGS_ERROR](state) {
    Object.assign(state, {
      isLoading: false,
    });
  },
  [types.REQUEST_LOAD_SETTINGS](state, data) {
    Object.assign(state, {
      kind: data.kind, // project or group
      apiEndpointUrl: data.apiEndpointUrl,
      docsUrl: data.docsUrl,
      isLoading: true,
    });
  },
};
