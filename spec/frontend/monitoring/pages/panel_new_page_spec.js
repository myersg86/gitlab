import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import { DASHBOARD_PAGE, PANEL_NEW_PAGE } from '~/monitoring/router/constants';
import * as types from '~/monitoring/stores/mutation_types';
import { createStore } from '~/monitoring/stores';
import DashboardPanelBuilder from '~/monitoring/components/dashboard_panel_builder.vue';

import PanelNewPage from '~/monitoring/pages/panel_new_page.vue';

const dashboard = 'dashboard.yml';
const mockYml = 'mock yml content';

// Button stub that can accept `to` as router links do
// https://bootstrap-vue.org/docs/components/button#comp-ref-b-button-props
const GlButtonStub = {
  extends: GlButton,
  props: {
    to: [String, Object],
  },
};

describe('monitoring/pages/panel_new_page', () => {
  let store;
  let wrapper;
  let $route;
  let $router;

  const mountComponent = (propsData = {}, routeParams = { dashboard }) => {
    $route = {
      params: routeParams,
    };
    $router = {
      push: jest.fn(),
    };

    wrapper = shallowMount(PanelNewPage, {
      propsData,
      store,
      stubs: {
        GlButton: GlButtonStub,
      },
      mocks: {
        $router,
        $route,
      },
    });
  };

  const findBackButton = () => wrapper.find(GlButtonStub);
  const findPanelBuilder = () => wrapper.find(DashboardPanelBuilder);

  beforeEach(() => {
    store = createStore();
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('back to dashboard button', () => {
    it('is rendered', () => {
      expect(findBackButton().exists()).toBe(true);
      expect(findBackButton().props('icon')).toBe('go-back');
    });

    it('links back to the dashboard', () => {
      const dashboardLocation = {
        name: DASHBOARD_PAGE,
        params: { dashboard },
      };

      expect(findBackButton().props('to')).toEqual(dashboardLocation);
    });
  });

  describe('dashboard panel builder', () => {
    it('is rendered', () => {
      expect(findPanelBuilder().exists()).toBe(true);
    });

    it('receives the yml content from the route', () => {
      mountComponent({ yml: mockYml });

      expect(findPanelBuilder().props('yml')).toBe(mockYml);
    });
  });

  describe('page routing', () => {
    it('route is not updated by default', () => {
      expect($router.push).not.toHaveBeenCalled();
    });

    it('route is updated when the yml content changes', () => {
      store.commit(`monitoringDashboard/${types.REQUEST_PANEL_PREVIEW}`, mockYml);

      return wrapper.vm.$nextTick().then(() => {
        expect($router.push).toHaveBeenCalledWith(
          expect.objectContaining({ name: PANEL_NEW_PAGE, query: { yml: mockYml } }),
        );
      });
    });
  });
});
