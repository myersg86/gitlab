import { mount, shallowMount } from '@vue/test-utils';
import { GlForm } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import OnDemandScansForm from 'ee/on_demand_scans/components/on_demand_scans_form.vue';
import runDastScanMutation from 'ee/on_demand_scans/graphql/dast_on_demand_scan_create.mutation.graphql';
import { redirectTo } from '~/lib/utils/url_utility';

const helpPagePath = `${TEST_HOST}/application_security/dast/index#on-demand-scans`;
const projectPath = 'group/project';
const defaultBranch = 'master';
const profilesLibraryPath = `${TEST_HOST}/${projectPath}/-/on_demand_scans/profiles`;
const newSiteProfilePath = `${TEST_HOST}/${projectPath}/-/on_demand_scans/profiles`;

const siteProfiles = [
  { id: 1, profileName: 'My first site profile', targetUrl: 'https://example.com' },
  { id: 2, profileName: 'My second site profile', targetUrl: 'https://foo.bar' },
];
const pipelineUrl = `${TEST_HOST}/${projectPath}/pipelines/123`;

jest.mock('~/lib/utils/url_utility', () => ({
  isAbsolute: jest.requireActual('~/lib/utils/url_utility').isAbsolute,
  redirectTo: jest.fn(),
}));

describe('OnDemandScansApp', () => {
  let wrapper;

  const findForm = () => wrapper.find(GlForm);
  const findSiteProfilesDropdown = () => wrapper.find('[data-testid="site-profiles-dropdown"]');
  const findManageSiteProfilesButton = () =>
    wrapper.find('[data-testid="manage-site-profiles-button"]');
  const findCreateNewSiteProfileLink = () =>
    wrapper.find('[data-testid="create-site-profile-link"]');
  const findAlert = () => wrapper.find('[data-testid="on-demand-scan-error"]');
  const submitForm = () => findForm().vm.$emit('submit', { preventDefault: () => {} });

  const wrapperFactory = (mountFn = shallowMount) => (options = {}) => {
    wrapper = mountFn(OnDemandScansForm, {
      attachToDocument: true,
      propsData: {
        helpPagePath,
        projectPath,
        defaultBranch,
        profilesLibraryPath,
        newSiteProfilePath,
        ...options.props,
      },
      computed: options.computed,
      data() {
        return { ...options.data };
      },
      mocks: {
        $apollo: {
          mutate: jest.fn(),
        },
      },
    });
  };
  const createComponent = wrapperFactory();
  const createFullComponent = wrapperFactory(mount);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders properly', () => {
    expect(wrapper.isVueInstance()).toBe(true);
  });

  describe('computed props', () => {
    describe('formData', () => {
      it('returns an object with a key:value mapping from the form object including the project path', () => {
        wrapper.vm.form = {
          siteProfile: {
            value: siteProfiles[0],
            state: null,
            feedback: '',
          },
        };
        expect(wrapper.vm.formData).toEqual({
          projectPath,
          siteProfile: siteProfiles[0],
        });
      });
    });

    describe('formHasErrors', () => {
      it('returns true if any of the fields are invalid', () => {
        wrapper.vm.form = {
          siteProfile: {
            value: siteProfiles[0],
            state: false,
            feedback: '',
          },
          foo: {
            value: 'bar',
            state: null,
          },
        };
        expect(wrapper.vm.formHasErrors).toBe(true);
      });

      it('returns false if none of the fields are invalid', () => {
        wrapper.vm.form = {
          siteProfile: {
            value: siteProfiles[0],
            state: null,
            feedback: '',
          },
          foo: {
            value: 'bar',
            state: null,
          },
        };
        expect(wrapper.vm.formHasErrors).toBe(false);
      });
    });

    describe('someFieldEmpty', () => {
      it('returns true if any of the fields are empty', () => {
        wrapper.vm.form = {
          siteProfile: {
            value: '',
            state: false,
            feedback: '',
          },
          foo: {
            value: 'bar',
            state: null,
          },
        };
        expect(wrapper.vm.someFieldEmpty).toBe(true);
      });

      it('returns false if no field is empty', () => {
        wrapper.vm.form = {
          siteProfile: {
            value: siteProfiles[0],
            state: null,
            feedback: '',
          },
          foo: {
            value: 'bar',
            state: null,
          },
        };
        expect(wrapper.vm.someFieldEmpty).toBe(false);
      });
    });

    describe('isSubmitDisabled', () => {
      it.each`
        formHasErrors | someFieldEmpty | expected
        ${true}       | ${true}        | ${true}
        ${true}       | ${false}       | ${true}
        ${false}      | ${true}        | ${true}
        ${false}      | ${false}       | ${false}
      `(
        'is $expected when formHasErrors is $formHasErrors and someFieldEmpty is $someFieldEmpty',
        ({ formHasErrors, someFieldEmpty, expected }) => {
          createComponent({
            computed: {
              formHasErrors: () => formHasErrors,
              someFieldEmpty: () => someFieldEmpty,
            },
          });

          expect(wrapper.vm.isSubmitDisabled).toBe(expected);
        },
      );
    });
  });

  describe('site profiles', () => {
    describe('when there are no site profiles yet', () => {
      beforeEach(() => {
        createFullComponent();
      });

      it('disables the link to manage site profiles', () => {
        expect(findManageSiteProfilesButton().props('disabled')).toBe(true);
      });

      it('shows a link to create a new site profile', () => {
        const link = findCreateNewSiteProfileLink();
        expect(link.exists()).toBe(true);
        expect(link.attributes('href')).toBe(newSiteProfilePath);
      });
    });

    describe('when there are site profiles', () => {
      beforeEach(() => {
        createComponent({
          data: {
            siteProfiles,
          },
        });
      });

      it('shows a dropdown containing the site profiles', () => {
        const dropdown = findSiteProfilesDropdown();
        expect(dropdown.exists()).toBe(true);
        expect(dropdown.element.children).toHaveLength(siteProfiles.length);
      });

      it('when a site profile is selected, its summary is displayed below the dropdown', async () => {
        wrapper.vm.form.siteProfile.value = siteProfiles[0].id;
        await wrapper.vm.$nextTick();
        const summary = wrapper.find('[data-testid="site-profile-summary"]');

        expect(summary.exists()).toBe(true);
        expect(summary.text()).toContain(siteProfiles[0].targetUrl);
      });
    });
  });

  describe('submission', () => {
    beforeEach(() => {
      createComponent({
        data: {
          siteProfiles,
        },
      });
    });

    describe('on success', () => {
      beforeEach(() => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue({ data: { runDastScan: { pipelineUrl, errors: [] } } });
        findSiteProfilesDropdown().vm.$emit('input', siteProfiles[0]);
        submitForm();
      });

      it('sets loading state', () => {
        expect(wrapper.vm.loading).toBe(true);
      });

      it('triggers GraphQL mutation', () => {
        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: runDastScanMutation,
          variables: {
            scanType: 'PASSIVE',
            branch: 'master',
            siteProfile: siteProfiles[0],
            projectPath,
          },
        });
      });

      it('redirects to the URL provided in the response', () => {
        expect(redirectTo).toHaveBeenCalledWith(pipelineUrl);
      });
    });

    describe('on top-level error', () => {
      beforeEach(async () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue();
        findSiteProfilesDropdown().vm.$emit('input', siteProfiles[0]);
        submitForm();
      });

      it('resets loading state', () => {
        expect(wrapper.vm.loading).toBe(false);
      });

      it('shows an alert', () => {
        expect(findAlert().exists()).toBe(true);
      });
    });

    describe('on errors as data', () => {
      const errors = ['error#1', 'error#2', 'error#3'];

      beforeEach(async () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue({ data: { runDastScan: { pipelineUrl: null, errors } } });
        findSiteProfilesDropdown().vm.$emit('input', siteProfiles[0]);
        submitForm();
      });

      it('resets loading state', () => {
        expect(wrapper.vm.loading).toBe(false);
      });

      it('shows an alert with the returned errors', () => {
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        errors.forEach(error => {
          expect(alert.text()).toContain(error);
        });
      });
    });
  });
});
