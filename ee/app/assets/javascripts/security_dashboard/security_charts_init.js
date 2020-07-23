import Vue from 'vue';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import UnavailableState from './components/unavailable_state.vue';
import createStore from './store';
import createRouter from './router';
import apolloProvider from './graphql/provider';

import GroupSecurityCharts from './components/group_security_charts.vue';

const isRequired = message => {
  throw new Error(message);
};

export default (
  /* eslint-disable @gitlab/require-i18n-strings */
  el = isRequired('No element was passed to the security dashboard initializer'),
  dashboardType = isRequired('No dashboard type was passed to the security dashboard initializer'),
  /* eslint-enable @gitlab/require-i18n-strings */
) => {
  if (el.dataset.isUnavailable) {
    return new Vue({
      el,
      render(createElement) {
        return createElement(UnavailableState, {
          props: {
            link: el.dataset.dashboardDocumentation,
            svgPath: el.dataset.emptyStateSvgPath,
          },
        });
      },
    });
  }

  const props = {};

  let component;

  if (dashboardType === DASHBOARD_TYPES.GROUP) {
    component = GroupSecurityCharts;
    props.groupFullPath = el.dataset.groupFullPath;
    props.vulnerableProjectsEndpoint = el.dataset.vulnerableProjectsEndpoint;
  }

  const router = createRouter();
  const store = createStore({ dashboardType });

  return new Vue({
    el,
    store,
    router,
    apolloProvider,
    provide: () => ({
      dashboardDocumentation: el.dataset.dashboardDocumentation,
      noVulnerabilitiesSvgPath: el.dataset.noVulnerabilitiesSvgPath,
      emptyStateSvgPath: el.dataset.emptyStateSvgPath,
      notEnabledScannersHelpPath: el.dataset.notEnabledScannersHelpPath,
      noPipelineRunScannersHelpPath: el.dataset.noPipelineRunScannersHelpPath,
    }),
    render(createElement) {
      return createElement(component, { props });
    },
  });
};
