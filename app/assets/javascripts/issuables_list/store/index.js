import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import state from './state';
import mutations from './mutations';

Vue.use(Vuex);

export const createStore = () => new Vuex.Store({
  actions,
  state,
  mutations,
});

export default createStore();
