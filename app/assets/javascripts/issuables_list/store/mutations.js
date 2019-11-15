import Vue from 'vue';

const SET_ISSUABLES_SUCCESS = 'SET_ISSUABLES_SUCCESS';
const SET_ISSUABLES_LOADING = 'SET_ISSUABLES_LOADING';
const SET_BULK_EDITING = 'SET_BULK_EDITING';
const SET_SELECTION_EMPTY = 'SET_SELECTION_EMPTY';
const SET_SELECT = 'SET_SELECT';
const SET_SELECTED_ID = 'SET_SELECTED_ID';
const DELETE_SELECTED_ID = 'DELETE_SELECTED_ID';

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
  [SET_SELECT](state, id) {
    Vue.set(state.selection, id, true);
  },
  [SET_SELECTED_ID](state, id) {
    Vue.set(state.selection, id, true);
  },
  [DELETE_SELECTED_ID](state, id) {
    Vue.delete(state.selection, id);
  },
};
