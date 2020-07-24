import Vue from 'vue';
import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';

import InsightsPage from 'ee/insights/components/insights_page.vue';
import InsightsChart from 'ee/insights/components/insights_chart.vue';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { createStore } from 'ee/insights/stores';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { chartInfo, pageInfo, pageInfoNoCharts, barChartData } from 'ee_jest/insights/mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Insights page component', () => {
  let store;

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});
  });

  describe('using mount component helper', () => {
    let component;
    let Component;

    beforeEach(() => {
      Component = Vue.extend(InsightsPage);
    });

    afterEach(() => {
      component.$destroy();
    });

    describe('no chart config available', () => {
      it('shows an empty state', () => {
        component = mountComponentWithStore(Component, {
          store,
          props: {
            queryEndpoint: `${TEST_HOST}/query`,
            pageConfig: pageInfoNoCharts,
          },
        });

        expect(component.$el.querySelector('.js-empty-state')).not.toBe(null);
      });
    });

    describe('charts configured', () => {
      beforeEach(() => {
        component = mountComponentWithStore(Component, {
          store,
          props: {
            queryEndpoint: `${TEST_HOST}/query`,
            pageConfig: pageInfo,
          },
        });
      });

      it('fetches chart data when mounted', () => {
        expect(store.dispatch).toHaveBeenCalledWith('insights/fetchChartData', {
          endpoint: `${TEST_HOST}/query`,
          chart: chartInfo,
        });
      });

      describe('pageConfig changes', () => {
        it('reflects new state', () => {
          component.pageConfig = pageInfoNoCharts;

          return component.$nextTick(() => {
            expect(component.$el.querySelector('.js-empty-state')).not.toBe(null);
          });
        });
      });
    });
  });

  describe('using test-utils', () => {
    let wrapper;
    beforeEach(() => {
      wrapper = shallowMount(InsightsPage, {
        localVue,
        store,
        propsData: {
          queryEndpoint: `${TEST_HOST}/query`,
          pageConfig: pageInfo,
        },
      });
    });

    describe('charts configured', () => {
      describe('when charts loading', () => {
        beforeEach(() => {
          const chartData = pageInfo.charts.reduce((memo, chart) => {
            return { ...memo, [chart.title]: {} };
          }, {});
          wrapper.setData({ chartData });
        });

        it('renders loading state', () => {
          const chartContainer = wrapper.find(InsightsChart);
          expect(chartContainer.props()).toMatchObject({
            loaded: false,
          });
        });

        it('does display chart area', () => {
          expect(wrapper.contains(InsightsChart)).toBe(true);
        });

        it('does not display chart', () => {
          expect(wrapper.contains(GlColumnChart)).toBe(false);
        });
      });

      describe('charts configured and loaded', () => {
        beforeEach(() => {
          const chartData = pageInfo.charts.reduce((memo, chart) => {
            return {
              ...memo,
              [chart.title]: {
                loaded: true,
                type: chart.type,
                description: '',
                data: barChartData,
                error: null,
              },
            };
          }, {});
          wrapper.setData({ chartData });
        });

        it('does not render loading state', () => {
          const chartContainer = wrapper.find(InsightsChart);
          expect(chartContainer.props()).toMatchObject({
            loaded: true,
          });
        });

        it('does display chart area', () => {
          expect(wrapper.contains(InsightsChart)).toBe(true);
        });
      });
    });
  });
});
