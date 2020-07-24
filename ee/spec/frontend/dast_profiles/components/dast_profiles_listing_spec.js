import { merge } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import { within } from '@testing-library/dom';
import DastProfilesListing from 'ee/dast_profiles/components/dast_profiles_listing.vue';

describe('EE - DastProfilesListing', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const defaultProps = {
      profiles: [],
    };

    wrapper = shallowMount(
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
  const getProfilesList = () => withinComponent().getByRole('list', { name: /site profiles/i });
  const getAllProfilesListItems = () => within(getProfilesList()).getAllByRole('listitem');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('empty state', () => {
    beforeEach(() => {
      createComponent();
    });
    it('shows a message to indicate that no profiles exist', () => {
      const emptyStateMessage = withinComponent().getByText(/no profiles created yet/i);

      expect(emptyStateMessage).not.toBe(null);
    });
  });

  describe('with profiles data', () => {
    const mockProfiles = [
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

    beforeEach(() => {
      createComponent({ propsData: { profiles: mockProfiles } });
    });

    it('renders a list of profiles', () => {
      expect(getProfilesList()).not.toBe(null);
      expect(getAllProfilesListItems()).toHaveLength(mockProfiles.length);
    });

    it.each(mockProfiles)('renders list item %# correctly', profile => {
      const { innerText } = getAllProfilesListItems()[mockProfiles.indexOf(profile)];

      expect(innerText).toContain(profile.profileName);
      expect(innerText).toContain(profile.targetUrl);
      expect(innerText).toContain(profile.validationStatus);
    });
  });
});
