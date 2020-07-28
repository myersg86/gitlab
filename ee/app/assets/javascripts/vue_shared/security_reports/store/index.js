import Vue from 'vue';
import Vuex from 'vuex';
import configureMediator from './mediator';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

import sast from './modules/sast';

Vue.use(Vuex);

export default () => {
  const store = new Vuex.Store({
    modules: {
      sast,
    },
    actions,
    getters,
    mutations,
    state: state(),
    plugins: [configureMediator],
  });

  console.log('store', store.state.hasError);

  return store;
};
