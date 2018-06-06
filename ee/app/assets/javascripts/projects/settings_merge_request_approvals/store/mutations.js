import types from './mutation_types';

export default {
  [types.RECEIVE_LOAD_SETTINGS](state, settings) {
    Object.assign(state, {
      settings,
      approvers: state.approvers,
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
      apiEndpointUrl: data.apiEndpointUrl,
      docsUrl: data.docsUrl,
      isLoading: true,
    });
  },
  [types.UPDATE_APPROVERS](state, data) {
    const settings = { ...state.settings };

    let approvers = [...settings.approvers];

    if (data.added) {
      approvers.push(data.added);
    }

    approvers = approvers.filter(user => {
      return data.val.includes(`${user.id}`);
    });

    Object.assign(state.settings, { approvers });
  },
};
