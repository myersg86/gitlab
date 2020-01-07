import { shallowMount } from '@vue/test-utils';
import DuplicateDashboardForm from '~/monitoring/components/duplicate_dashboard_form.vue';

import { dashboardGitResponse } from '../mock_data';

function createComponent(props, options = {}) {
  return shallowMount(DuplicateDashboardForm, {
    propsData: {
      ...props,
      dashboard: dashboardGitResponse[0],
      defaultBranch: 'master',
    },
    sync: false,
    ...options,
  });
}

describe('DuplicateDashboardForm', () => {
  it('renders correctly', () => {
    const wrapper = createComponent();
    expect(wrapper.exists()).toEqual(true);
  });

  // TODO More tests
});
