import { shallowMount } from '@vue/test-utils';
import DashboardsDropdown from '~/monitoring/components/dashboards_dropdown.vue';

import { GlDropdownItem } from '@gitlab/ui';

import { dashboardGitResponse } from '../mock_data';

function createComponent(props) {
  return shallowMount(DashboardsDropdown, {
    propsData: {
      ...props,
      allDashboards: dashboardGitResponse,
      defaultBranch: 'master',
    },
    sync: false,
  });
}

describe('DashboardsDropdown', () => {
  let wrapper;

  const findItems = () => wrapper.findAll(GlDropdownItem);
  const findItemAt = i => wrapper.findAll(GlDropdownItem).at(i);

  describe('when it receives dashboards data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });
    it('displays an item for each dashboard', () => {
      expect(wrapper.findAll(GlDropdownItem).length).toEqual(dashboardGitResponse.length);
    });

    it('displays items with the dashboard display name', () => {
      expect(findItemAt(0).text()).toBe(dashboardGitResponse[0].display_name);
      expect(findItemAt(1).text()).toBe(dashboardGitResponse[1].display_name);
      expect(findItemAt(2).text()).toBe(dashboardGitResponse[2].display_name);
    });
  });

  describe('when a system dashboard is selected', () => {
    beforeEach(() => {
      wrapper = createComponent({
        selectedDashboard: dashboardGitResponse[0],
      });
    });

    it('displays an item for each dashboard plus a "duplicate dashboard" item', () => {
      const item = wrapper.findAll({ ref: 'duplicateDashboardItem' });

      expect(findItems().length).toEqual(dashboardGitResponse.length + 1);
      expect(item.length).toBe(1);
    });
  });

  describe('when a dashboard is selected by the user', () => {
    beforeEach(() => {
      wrapper = createComponent();
      findItemAt(1).vm.$emit('click');
    });

    it('emits a "selectDashboard" event', () => {
      expect(wrapper.emitted().selectDashboard).toBeTruthy();
    });
    it('emits a "selectDashboard" event with dashboard information', () => {
      expect(wrapper.emitted().selectDashboard[0]).toEqual([dashboardGitResponse[1]]);
    });
  });

  // TODO Test modal logic
});
