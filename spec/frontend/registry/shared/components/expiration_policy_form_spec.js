import { mount } from '@vue/test-utils';
import stubChildren from 'helpers/stub_children';
import component from '~/registry/shared/components/expiration_policy_form.vue';

import { NAME_REGEX_LENGTH } from '~/registry/shared/constants';
import { formOptions } from '../mock_data';

describe('Expiration Policy Form', () => {
  let wrapper;

  const FORM_ELEMENTS_ID_PREFIX = '#expiration-policy';

  const GlLoadingIcon = { name: 'gl-loading-icon-stub', template: '<svg></svg>' };

  const findFormGroup = name => wrapper.find(`${FORM_ELEMENTS_ID_PREFIX}-${name}-group`);
  const findFormElements = (name, parent = wrapper) =>
    parent.find(`${FORM_ELEMENTS_ID_PREFIX}-${name}`);
  const findCancelButton = () => wrapper.find({ ref: 'cancel-button' });
  const findSaveButton = () => wrapper.find({ ref: 'save-button' });
  const findForm = () => wrapper.find({ ref: 'form-element' });
  const findLoadingIcon = (parent = wrapper) => parent.find(GlLoadingIcon);

  const mountComponent = () => {
    wrapper = mount(component, {
      stubs: {
        ...stubChildren(component),
        GlCard: false,
        GlLoadingIcon,
      },
      propsData: {
        formOptions,
      },
      methods: {
        // override idGenerator to avoid having to test with dynamic uid
        idGenerator: value => value,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe.each`
    elementName        | modelName       | value    | disabledByToggle
    ${'toggle'}        | ${'enabled'}    | ${true}  | ${'not disabled'}
    ${'interval'}      | ${'older_than'} | ${'foo'} | ${'disabled'}
    ${'schedule'}      | ${'cadence'}    | ${'foo'} | ${'disabled'}
    ${'latest'}        | ${'keep_n'}     | ${'foo'} | ${'disabled'}
    ${'name-matching'} | ${'name_regex'} | ${'foo'} | ${'disabled'}
  `(
    `${FORM_ELEMENTS_ID_PREFIX}-$elementName form element`,
    ({ elementName, modelName, value, disabledByToggle }) => {
      let formGroup;
      beforeEach(() => {
        formGroup = findFormGroup(elementName);
      });
      it(`${elementName} form group exist in the dom`, () => {
        expect(formGroup.exists()).toBe(true);
      });

      it(`${elementName} form group has a label-for property`, () => {
        expect(formGroup.attributes('label-for')).toBe(`expiration-policy-${elementName}`);
      });

      it(`${elementName} form group has a label-cols property`, () => {
        wrapper.setProps({ labelCols: '1' });
        return wrapper.vm.$nextTick().then(() => {
          expect(formGroup.attributes('label-cols')).toBe('1');
        });
      });

      it(`${elementName} form group has a label-align property`, () => {
        wrapper.setProps({ labelAlign: 'foo' });
        return wrapper.vm.$nextTick().then(() => {
          expect(formGroup.attributes('label-align')).toBe('foo');
        });
      });

      it(`${elementName} form group contains an input element`, () => {
        expect(findFormElements(elementName, formGroup).exists()).toBe(true);
      });

      it(`${elementName} form element change updated ${modelName} with ${value}`, () => {
        const element = findFormElements(elementName, formGroup);
        const modelUpdateEvent = element.vm.$options.model
          ? element.vm.$options.model.event
          : 'input';
        element.vm.$emit(modelUpdateEvent, value);
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.emitted('input')).toEqual([[{ [modelName]: value }]]);
        });
      });

      it(`${elementName} is ${disabledByToggle} by enabled set to false`, () => {
        wrapper.setProps({ settings: { enabled: false } });
        const expectation = disabledByToggle === 'disabled' ? 'true' : undefined;
        expect(findFormElements(elementName, formGroup).attributes('disabled')).toBe(expectation);
      });
    },
  );

  describe('form actions', () => {
    let form;
    beforeEach(() => {
      form = findForm();
    });

    describe('cancel button', () => {
      it('has type reset', () => {
        expect(findCancelButton().attributes('type')).toBe('reset');
      });

      it('is disabled when disableCancelButton is true', () => {
        wrapper.setProps({ disableCancelButton: true });
        return wrapper.vm.$nextTick().then(() => {
          expect(findCancelButton().attributes('disabled')).toBe('true');
        });
      });

      it('is disabled isLoading is true', () => {
        wrapper.setProps({ isLoading: true });
        return wrapper.vm.$nextTick().then(() => {
          expect(findCancelButton().attributes('disabled')).toBe('true');
        });
      });

      it('is enabled when isLoading and disableCancelButton are false', () => {
        wrapper.setProps({ disableCancelButton: false, isLoading: false });
        return wrapper.vm.$nextTick().then(() => {
          expect(findCancelButton().attributes('disabled')).toBe(undefined);
        });
      });
    });

    describe('form cancel event', () => {
      it('calls the appropriate function', () => {
        form.trigger('reset');
        expect(wrapper.emitted('reset')).toBeTruthy();
      });
    });

    it('save has type submit', () => {
      expect(findSaveButton().attributes('type')).toBe('submit');
    });

    describe('when isLoading is true', () => {
      beforeEach(() => {
        wrapper.setProps({ isLoading: true });
      });

      it.each`
        elementName
        ${'toggle'}
        ${'interval'}
        ${'schedule'}
        ${'latest'}
        ${'name-matching'}
      `(`${FORM_ELEMENTS_ID_PREFIX}-$elementName is disabled`, ({ elementName }) => {
        expect(findFormElements(elementName).attributes('disabled')).toBe('true');
      });

      it('submit button is disabled and shows a spinner', () => {
        const button = findSaveButton();
        expect(button.attributes('disabled')).toBeTruthy();
        expect(findLoadingIcon(button)).toExist();
      });
    });

    describe('form submit event ', () => {
      it('calls the appropriate function', () => {
        form.trigger('submit');
        expect(wrapper.emitted('submit')).toBeTruthy();
      });
    });
  });

  describe('form validation', () => {
    describe(`when name regex is longer than ${NAME_REGEX_LENGTH}`, () => {
      const invalidString = new Array(NAME_REGEX_LENGTH + 2).join(',');

      beforeEach(() => {
        wrapper.setProps({ value: { name_regex: invalidString } });
      });

      it('save btn is disabled', () => {
        expect(findSaveButton().attributes('disabled')).toBeTruthy();
      });

      it('nameRegexState is false', () => {
        expect(wrapper.vm.nameRegexState).toBe(false);
      });
    });

    it('if the user did not type validation is null', () => {
      wrapper.setProps({ value: { name_regex: '' } });
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.nameRegexState).toBe(null);
        expect(findSaveButton().attributes('disabled')).toBeFalsy();
      });
    });

    it(`if the user typed and is less than ${NAME_REGEX_LENGTH} state is true`, () => {
      wrapper.setProps({ value: { name_regex: 'foo' } });
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.nameRegexState).toBe(true);
      });
    });
  });

  describe('help text', () => {
    it('toggleDescriptionText text reflects enabled property', () => {
      const toggleHelpText = findFormGroup('toggle').find('span');
      expect(toggleHelpText.html()).toContain('disabled');
      wrapper.setProps({ value: { enabled: true } });
      return wrapper.vm.$nextTick().then(() => {
        expect(toggleHelpText.html()).toContain('enabled');
      });
    });
  });
});
