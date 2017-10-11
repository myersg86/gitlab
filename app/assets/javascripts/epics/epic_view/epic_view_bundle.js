import Vue from 'vue';
import EpicViewApp from './components/epic_view_app.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#epic-view-app',
  components: {
    'epic-view-app': EpicViewApp,
  },
  render: createElement => createElement('epic-view-app'),
}));
