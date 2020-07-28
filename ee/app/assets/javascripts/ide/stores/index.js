import Vue from 'vue';
import Vuex from 'vuex';
import createState from './state';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import { createStoreOptions as ceCreateStoreOptions } from '~/ide/stores/index';

Vue.use(Vuex);

export const createStoreOptions = () => ({
  ...ceCreateStoreOptions(),
  state: createState(),
  actions,
  getters,
  mutations,
});

export const createStore = () => new Vuex.Store(createStoreOptions());
