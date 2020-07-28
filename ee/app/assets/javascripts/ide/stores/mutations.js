import * as types from './mutation_types';
import mutations from '~/ide/stores/mutations';

export default {
  [types.SET_CONFIG](state, config) {
    Object.assign(state, { config });
  },
  ...mutations,
};
