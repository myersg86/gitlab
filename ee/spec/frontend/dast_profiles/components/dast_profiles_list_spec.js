import { merge } from 'lodash';
import { mount } from '@vue/test-utils';
import { within } from '@testing-library/dom';
import DastProfilesListing from 'ee/dast_profiles/components/dast_profiles_list.vue';

describe('EE - DastProfilesList', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const defaultProps = {
      profiles: [],
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
  const getProfilesTable = () => withinComponent().getByRole('table', { name: /site profiles/i });
  const getProfilesTableBody = () => within(getProfilesTable()).getAllByRole('rowgroup')[1]; // `0` is thead
  const getAllProfilesRows = () => within(getProfilesTableBody()).getAllByRole('row');

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
      expect(getProfilesTable()).not.toBe(null);
      expect(getAllProfilesRows()).toHaveLength(mockProfiles.length);
    });

    it.each(mockProfiles)('renders list item %# correctly', profile => {
      const { innerText } = getAllProfilesRows()[mockProfiles.indexOf(profile)];

      expect(innerText).toContain(profile.profileName);
      expect(innerText).toContain(profile.targetUrl);
      expect(innerText).toContain(profile.validationStatus);
    });
  });
});
