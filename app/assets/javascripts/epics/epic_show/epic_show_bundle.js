import Vue from 'vue';
import EpicShowApp from './components/epic_show_app.vue';

document.addEventListener('DOMContentLoaded', () => {
  const el = document.querySelector('#epic-show-app');
  const metaData = JSON.parse(el.dataset.meta);
  const initialData = JSON.parse(el.dataset.initial);

  const { created, author } = metaData;

  const {
    endpoint,
    canUpdate,
    canDestroy,
    markdownPreviewPath,
    markdownDocsPath,
    groupPath,
    initialTitleHtml,
    initialTitleText,
    initialDescriptionHtml,
    initialDescriptionText
  } = initialData;

  return new Vue({
    el,
    components: {
      'epic-show-app': EpicShowApp,
    },
    render: createElement => createElement('epic-show-app', {
      props: {
        endpoint,
        canUpdate,
        canDestroy,
        markdownPreviewPath,
        markdownDocsPath,
        groupPath,
        initialTitleHtml,
        initialTitleText,
        initialDescriptionHtml,
        initialDescriptionText,
        created,
        author,
      },
    }),
  })
});
