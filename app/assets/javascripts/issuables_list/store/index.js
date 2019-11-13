import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as state from './state';

Vue.use(Vuex);

export const createStore = () => new Vuex.Store({
  actions,
  state,
});

export default createStore();
