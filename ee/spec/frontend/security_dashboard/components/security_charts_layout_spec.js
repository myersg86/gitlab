import { shallowMount } from '@vue/test-utils';
import SecurityChartsLayout from 'ee/security_dashboard/components/security_charts_layout.vue';

describe('Security Charts Layout component', () => {
  let wrapper;

  const DummyComponent = {
    name: 'dummy-component',
    template: '<p>dummy component</p>',
  };

  const findSlot = () => wrapper.find('.security-charts');

  const createWrapper = slots => {
    wrapper = shallowMount(SecurityChartsLayout, { slots });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('loaded', () => {
    beforeEach(() => {
      createWrapper({ default: DummyComponent });
    });

    it('should render the default slot', () => {
      const slot = findSlot();
      expect(slot.find(DummyComponent).exists()).toBe(true);
    });
  });
});
