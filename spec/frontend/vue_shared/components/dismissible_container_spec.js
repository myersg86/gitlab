import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { shallowMount } from '@vue/test-utils';
import dismissibleContainer from '~/vue_shared/components/dismissible_container.vue';

describe('DismissibleContainer', () => {
  let wrapper;
  let mockAxios;
  const propsData = {
    path: 'some/path',
    featureId: 'some-feature-id',
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    wrapper = shallowMount(dismissibleContainer, { propsData });
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.restore();
  });

  describe('template', () => {
    const findBtn = () => wrapper.find('[data-testid="suggest-close"]');

    it('successfully dismisses', () => {
      mockAxios.onPost(propsData.path).replyOnce(200);
      const button = findBtn();

      button.trigger('click');

      expect(wrapper.emitted().dismiss).toBeTruthy();
    });
  });
});
