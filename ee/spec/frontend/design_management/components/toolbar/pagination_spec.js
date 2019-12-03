import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Pagination from 'ee/design_management/components/toolbar/pagination.vue';
import projectQuery from 'ee/design_management/graphql/queries/project.query.graphql';
import createMockProvider from '~/lib/mock_provider/mock_provider';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Design management pagination component', () => {
  let wrapper;

  function createComponent(apolloProvider) {
    wrapper = shallowMount(Pagination, {
      localVue,
      propsData: {
        id: '2',
      },
      provide: apolloProvider,
    });
  }

  beforeEach(() => {
    const mocks = [
      {
        request: {
          query: projectQuery,
          variables: {
            name: 'Buck',
          },
        },
        result: {
          data: {
            project: {
              issue: {
                designsCollection: {
                  designs: {
                    edges: [{ node: { id: '1' } }, { node: { id: '2' } }],
                  },
                },
              },
            },
          },
        },
      },
    ];

    const mockProvider = createMockProvider(mocks, false);
    createComponent(mockProvider);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('hides components when designs are empty', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders pagination buttons', () => {
    // wrapper.setData({
    //   designs: [{ id: '1' }, { id: '2' }],
    // });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
