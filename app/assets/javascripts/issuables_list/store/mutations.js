const SET_ISSUABLES_SUCCESS = 'SET_ISSUABLES_SUCCESS';
const SET_ISSUABLES_LOADING = 'SET_ISSUABLES_LOADING';

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
  }
};
