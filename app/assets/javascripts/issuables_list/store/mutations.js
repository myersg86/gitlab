const SET_ISSUABLES_SUCCESS = 'SET_ISSUABLES_SUCCESS';
const SET_ISSUABLES_LOADING = 'SET_ISSUABLES_LOADING';
const SET_BULK_EDITING = 'SET_BULK_EDITING';
const SET_SELECTION_EMPTY = 'SET_SELECTION_EMPTY';

export default {
  [SET_ISSUABLES_SUCCESS](state, resp) {
    Object.assign(state, {
      issuables: resp.data,
      totalItems: Number(resp.headers['x-total']),
      page: Number(resp.headers['x-page']),
    });
  },
  [SET_ISSUABLES_LOADING](state, bool) {
    state.loading = bool;
  },
  [SET_BULK_EDITING](state, bool) {
    state.isBulkEditing = bool;
  },
  [SET_SELECTION_EMPTY](state) {
    state.selection = {};
  },
};
