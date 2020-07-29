import { merge } from 'lodash';
import { mount } from '@vue/test-utils';
import { within, fireEvent } from '@testing-library/dom';
import DastProfilesListing from 'ee/dast_profiles/components/dast_profiles_list.vue';

describe('EE - DastProfilesList', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const defaultProps = {
      profiles: [],
      hasMorePages: false,
    };

    wrapper = mount(
      DastProfilesListing,
      merge(
        {},
        {
          propsData: defaultProps,
        },
        options,
      ),
    );
  };

  const withinComponent = () => within(wrapper.element);
  const getTable = () => withinComponent().getByRole('table', { name: /site profiles/i });
  const getAllRowGroups = () => within(getTable()).getAllByRole('rowgroup');
  const getTableBody = () => {
    // first item is the table head
    const [, tableBody] = getAllRowGroups();
    return tableBody;
  };
  const getAllTableRows = () => within(getTableBody()).getAllByRole('row');
  const loadMoreButton = () => withinComponent().queryByRole('button', { name: /load more/i });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loading', () => {});

  describe('with no profiles data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a message to indicate that no profiles exist', () => {
      const emptyStateMessage = withinComponent().getByText(/no profiles created yet/i);

      expect(emptyStateMessage).not.toBe(null);
    });
  });

  describe('with profiles data', () => {
    const profiles = [
      {
        id: 1,
        profileName: 'Profile 1',
        targetUrl: 'http://example-1.com',
        validationStatus: 'Pending',
      },
      {
        id: 2,
        profileName: 'Profile 2',
        targetUrl: 'http://example-2.com',
        validationStatus: 'Pending',
      },
    ];

    describe('profiles list', () => {
      beforeEach(() => {
        createComponent({ propsData: { profiles } });
      });

      it('renders a list of profiles', () => {
        expect(getTable()).not.toBe(null);
        expect(getAllTableRows()).toHaveLength(profiles.length);
      });

      it.each(profiles)('renders list item %# correctly', profile => {
        const { innerText } = getAllTableRows()[profiles.indexOf(profile)];

        expect(innerText).toContain(profile.profileName);
        expect(innerText).toContain(profile.targetUrl);
        expect(innerText).toContain(profile.validationStatus);
      });
    });

    describe('load more profiles', () => {
      it('does not show that there are more projects to be loaded per default', () => {
        createComponent({ propsData: { profiles } });

        expect(loadMoreButton()).toBe(null);
      });

      it('shows that there are more projects to be loaded', () => {
        createComponent({ propsData: { profiles, hasMoreProfilesToLoad: true } });

        expect(loadMoreButton()).not.toBe(null);
      });

      it('emits "loadMore" when the load-more button is clicked', async () => {
        expect(wrapper.emitted('loadMoreProfiles')).toBe(undefined);

        await fireEvent.click(loadMoreButton(), {});

        expect(wrapper.emitted('loadMoreProfiles')).toEqual(expect.any(Array));
      });
    });
  });

  describe('with more profiles to load', () => {});

  describe('with errors', () => {});
});
