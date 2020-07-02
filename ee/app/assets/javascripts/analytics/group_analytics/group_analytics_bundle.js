import Vue from 'vue';
import GroupActivityCard from './components/group_activity_card.vue';

export default () => {
  const container = document.getElementById('js-group-activity');

  if (!container) return;

  const { groupFullPath, groupName, reportPagesPath } = container.dataset;
  const { reportPages: enableReportPages } = gon?.features;

  // eslint-disable-next-line no-new
  new Vue({
    el: container,
    provide: {
      groupFullPath,
      groupName,
      reportPagesPath,
      enableReportPages,
    },
    render(h) {
      return h(GroupActivityCard);
    },
  });
};
