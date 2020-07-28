import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Ide from 'ee/ide/components/ide.vue';
import { createStore } from 'ee/ide/stores';
import services from '~/ide/services';
import { file } from 'jest/ide/helpers';
import waitForPromises from 'jest/helpers/wait_for_promises';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EE Ide', () => {
  let wrapper;
  let vm;
  let store;
  let state;

  let originalGon;

  function createComponent() {
    wrapper = shallowMount(Ide, { localVue, store });
    vm = wrapper.vm;
  }

  beforeEach(() => {
    originalGon = window.gon;

    window.gon = { features: { ideSchemaConfig: true } };

    store = createStore();

    state = store.state;
    state.currentProjectId = 'gitlab-org/gitlab';
    state.currentBranchId = 'master';
    state.entries = {};
    state.trees['gitlab-org/gitlab/master'] = { loading: true };

    jest.spyOn(services, 'getFileData').mockResolvedValue();
    jest.spyOn(services, 'getRawFileData').mockResolvedValue('');
  });

  afterEach(() => {
    window.gon = originalGon;

    wrapper.destroy();
    wrapper = null;
  });

  it('fetches IDE config and registers schemas when the tree is loaded', async () => {
    createComponent();

    jest.spyOn(vm, 'fetchConfig');
    jest.spyOn(vm, 'registerSchemasFromConfig');

    Vue.set(state, 'trees', { 'gitlab-org/gitlab/master': { loading: false } });
    Vue.set(state, 'entries', {
      '.gitlab/.gitlab-webide.yml': {
        ...file(),
        path: '.gitlab/.gitlab-webide.yml',
      },
    });

    await waitForPromises();

    expect(vm.fetchConfig).toHaveBeenCalled();
    expect(vm.registerSchemasFromConfig).toHaveBeenCalled();
  });
});
