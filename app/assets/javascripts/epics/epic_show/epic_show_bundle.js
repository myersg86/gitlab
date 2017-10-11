import Vue from 'vue';
import EpicShowApp from './components/epic_show_app.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#epic-show-app',
  components: {
    'epic-show-app': EpicShowApp,
  },
  render: createElement => createElement('epic-show-app'),
}));
