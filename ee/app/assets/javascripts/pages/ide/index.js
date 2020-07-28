import { startIde } from '~/ide/index';
import { createStore } from 'ee/ide/stores';
import extendStore from '~/ide/stores/extend';
import EEIde from 'ee/ide/components/ide.vue';

startIde({
  createStore,
  extendStore,
  rootComponent: EEIde,
});
