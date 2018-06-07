import Vue from 'vue';
import ApprovalSettings from './components/approval_settings.vue';
import store from './store';

export default () => {
  const approvalSettingsRootElement = document.querySelector('.js-merge-request-approvals-root');

  store.dispatch('loadSettings', {
    approvalsApiUrl: approvalSettingsRootElement.dataset.approvalsEndpoint,
    approversApiUrl: approvalSettingsRootElement.dataset.approversEndpoint,
    projectId: approvalSettingsRootElement.dataset.projectId,
  });

  if (approvalSettingsRootElement) {
    // eslint-disable-next-line no-new
    new Vue({
      el: approvalSettingsRootElement,
      store,
      components: {
        ApprovalSettings,
      },
      render(createElement) {
        return createElement(ApprovalSettings);
      },
    });
  }
};
