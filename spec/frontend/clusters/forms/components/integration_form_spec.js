import IntegrationForm from '~/clusters/forms/components/integration_form.vue';
import { createStore } from '~/clusters/forms/stores/index';
import { mount } from '@vue/test-utils';
import { GlToggle } from '@gitlab/ui';

describe('ClusterIntegrationForm', () => {
  let wrapper;
  let store;

  const glToggle = () => wrapper.find(GlToggle);
  const toggleButton = () => glToggle().find('button');
  const toggleInput = () => wrapper.find('[data-testid="hidden-toggle-input"]');
  const environmentScope = () => wrapper.find('[data-testid="hidden-environment-scope-input"]');
  const baseDomain = () => wrapper.find('[data-testid="hidden-base-domain-input"]');
  const saveButton = () => wrapper.find('[data-qa-selector="save_changes_button"]');

  const createWrapper = () => {
    store = createStore({
      enabled: 'true',
      editable: 'true',
      environmentScope: '*',
      baseDomain: 'testDomain',
    });
    wrapper = mount(IntegrationForm, { store });
    return wrapper.vm.$nextTick();
  };

  beforeEach(() => {
    return createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('creates the toggle and label', () => {
    expect(wrapper.text()).toContain('GitLab Integration');
    expect(wrapper.contains(GlToggle)).toBe(true);
  });

  it('initializes toggle with store value', () => {
    expect(toggleButton().classes()).toContain('is-checked');
    expect(toggleInput().attributes('value')).toBe('true');
  });

  it('switches the toggle value on click', () => {
    toggleButton().trigger('click');
    wrapper.vm.$nextTick(() => {
      expect(toggleButton().classes()).not.toContain('is-checked');
      expect(toggleInput().attributes('value')).toBe('false');
    });
  });

  it('creates the environment scope input', () => {
    expect(wrapper.text()).toContain('Environment scope');
    expect(environmentScope().attributes('value')).toBe('*');
  });

  it('creates the base domain input', () => {
    expect(wrapper.text()).toContain('Base domain');
    expect(baseDomain().attributes('value')).toBe('testDomain');
  });

  it('disables the save button if no change to the form', () => {
    expect(saveButton().attributes('disabled')).toBe('disabled');
  });

  it('enables the save button when form changes', () => {
    expect(saveButton().attributes('disabled')).toBe('disabled');
    toggleButton().trigger('click');
    wrapper.vm.$nextTick(() => {
      expect(saveButton().attributes('disabled')).not.toBe('disabled');
    });
  });
});
