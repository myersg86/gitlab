import types from './mutation_types';

const updateList = (state, data, field) => {
  let list = [...state.settings[field]];

  if (data.added) {
    list.push(data.added);
  }

  list = list.filter(entry => data.val.includes(`${entry.id}`));

  Object.assign(state.settings, { [field]: list });
};

export default {
  [types.RECEIVE_LOAD_SETTINGS](state, settings) {
    Object.assign(state, {
      settings,
      isLoading: false,
      isSaving: false,
    });
  },
  [types.RECEIVE_LOAD_SETTINGS_ERROR](state) {
    Object.assign(state, {
      isLoading: false,
    });
  },
  [types.RECEIVE_UPDATED_SETTINGS_ERROR](state) {
    Object.assign(state, {
      isSaving: false,
    });
  },
  [types.REQUEST_LOAD_SETTINGS](state, data) {
    Object.assign(state, {
      approvalsApiUrl: data.approvalsApiUrl,
      approversApiUrl: data.approversApiUrl,
      projectId: data.projectId,
      isLoading: true,
    });
  },
  [types.UPDATE_APPROVERS](state, data) {
    updateList(state, data, 'approvers');
  },
  [types.UPDATE_APPROVER_GROUPS](state, data) {
    updateList(state, data, 'approver_groups');
  },
  [types.REQUEST_UPDATED_SETTINGS](state) {
    Object.assign(state, {
      isSaving: true,
    });
  },
};
