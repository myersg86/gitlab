import $ from 'jquery';
import axios from '../lib/utils/axios_utils';
import flash from '../flash';
import { __ } from '~/locale';
import initForm from './edit';
import eventHub from './edit/event_hub';

export default class IntegrationSettingsForm {
  constructor(formSelector) {
    this.$form = $(formSelector);
    this.formActive = false;

    this.vue = null;

    // Form Metadata
    this.testEndPoint = this.$form.data('testUrl');
  }

  init() {
    // Init Vue component
    this.vue = initForm(
      document.querySelector('.js-vue-integration-settings'),
      document.querySelector('.js-vue-admin-integration-settings'),
    );
    eventHub.$on('toggle', active => {
      this.formActive = active;
      this.toggleServiceState();
    });
    eventHub.$on('testIntegration', () => {
      this.testIntegration();
    });
  }

  testIntegration() {
    // Service was marked active so now we check;
    // 1) If form contents are valid
    // 2) If this service can be tested
    // If both conditions are true, we override form submission
    // and test the service using provided configuration.
    if (this.$form.get(0).checkValidity()) {
      // eslint-disable-next-line no-jquery/no-serialize
      this.testSettings(this.$form.serialize());
    } else {
      eventHub.$emit('validateForm');
      this.vue.$store.dispatch('setIsTesting', false);
    }
  }

  /**
   * Change Form's validation enforcement based on service status (active/inactive)
   */
  toggleServiceState() {
    if (this.formActive) {
      this.$form.removeAttr('novalidate');
    } else if (!this.$form.attr('novalidate')) {
      this.$form.attr('novalidate', 'novalidate');
    }
  }

  /**
   * Test Integration config
   */
  testSettings(formData) {
    return axios
      .put(this.testEndPoint, formData)
      .then(({ data }) => {
        if (data.error) {
          let flashActions;

          if (data.test_failed) {
            flashActions = {
              title: __('Save anyway'),
              clickHandler: e => {
                e.preventDefault();
                this.$form.submit();
              },
            };
          }

          flash(`${data.message} ${data.service_response}`, 'alert', document, flashActions);
        } else {
          this.vue.$toast.show(__('Test successful!'));
        }
        this.vue.$store.dispatch('setIsTesting', false);
      })
      .catch(() => {
        this.vue.$toast.show(__('Something went wrong on our end.'), {
          type: 'error',
        });
        this.vue.$store.dispatch('setIsTesting', false);
      });
  }
}
