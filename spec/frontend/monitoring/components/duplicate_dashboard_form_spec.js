import { mount } from '@vue/test-utils';
import DuplicateDashboardForm from '~/monitoring/components/duplicate_dashboard_form.vue';

import { dashboardGitResponse } from '../mock_data';

describe('DuplicateDashboardForm', () => {
  let wrapper;

  const defaultBranch = 'master';

  const findByRef = ref => wrapper.find({ ref });

  const setValue = (ref, val) => {
    findByRef(ref).setValue(val);
  };

  const setChecked = value => {
    const input = wrapper.find(`.form-check-input[value="${value}"]`);
    input.element.checked = true;
    input.trigger('click');
    input.trigger('change');
  };

  beforeEach(() => {
    // Prefer `mount` to render native input elements
    wrapper = mount(DuplicateDashboardForm, {
      propsData: {
        dashboard: dashboardGitResponse[0],
        defaultBranch,
      },
      sync: false,
    });
  });

  it('renders correctly', () => {
    expect(wrapper.exists()).toEqual(true);
  });

  it('renders form elements', () => {
    expect(findByRef('fileName').exists()).toEqual(true);
    expect(findByRef('branchName').exists()).toEqual(true);
    expect(findByRef('branchOption').exists()).toEqual(true);
    expect(findByRef('commitMessage').exists()).toEqual(true);
  });

  describe('emits `change` event', () => {
    const lastChange = () =>
      wrapper.vm.$nextTick().then(() => {
        wrapper.find('form').trigger('change');

        // Resolves to the last emitted change
        const changes = wrapper.emitted().change;
        return changes[changes.length - 1][0];
      });

    it('with the inital form values', () => {
      expect(wrapper.emitted().change).toHaveLength(1);
      expect(lastChange()).resolves.toEqual({
        branch: '',
        commitMessage: expect.any(String),
        dashboard: dashboardGitResponse[0].path,
        fileName: 'common_metrics.yml',
      });
    });

    it('containing an inputted file name', () => {
      setValue('fileName', 'my_dashboard.yml');

      expect(lastChange()).resolves.toMatchObject({
        fileName: 'my_dashboard.yml',
      });
    });

    it('containing a default commit message when no message is set', () => {
      setValue('commitMessage', '');

      expect(lastChange()).resolves.toMatchObject({
        commitMessage: expect.stringContaining('Create custom dashboard'),
      });
    });

    it('containing an inputted commit message', () => {
      setValue('commitMessage', 'My commit message');

      expect(lastChange()).resolves.toMatchObject({
        commitMessage: expect.stringContaining('My commit message'),
      });
    });

    it('containing an inputted branch name', () => {
      setChecked('NEW');
      setValue('branchName', 'a-new-branch');

      expect(lastChange()).resolves.toMatchObject({
        branch: 'a-new-branch',
      });
    });

    it('containing a default branch selection and ignoring the define branch', () => {
      setChecked('DEFAULT');
      setValue('branchName', 'a-new-branch');

      expect(lastChange()).resolves.toMatchObject({
        branch: defaultBranch,
      });
    });

    it('focuses on the branch name input when branch option is chosen', done => {
      setChecked('NEW');

      wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.find('form').trigger('change');
          expect(findByRef('branchName').is(':focus')).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
