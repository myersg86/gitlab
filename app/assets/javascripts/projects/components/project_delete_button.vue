<script>
import { GlAlert } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import SharedDeleteButton from './shared/delete_button.vue';

export default {
  components: {
    GlAlert,
    SharedDeleteButton,
  },
  props: {
    confirmPhrase: {
      type: String,
      required: true,
    },
    formPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    alertBodyHtml() {
      return sprintf(this.$options.strings.alertBody, { strongOpen: '<strong>', strongClose: '</strong>'}, false);
    },
  },
  strings: {
    alertTitle: __('You are about to permanently delete this project'),
    alertBody: __(
      'Once a project is permanently deleted it %{strongOpen}cannot be recovered%{strongClose}. Permanently deleting this project will %{strongOpen}immediately delete%{strongClose} its respositories and %{strongOpen}all related resources%{strongClose} including issues, merge requests etc.',
    ),
    modalBody: __(
      "This action cannot be undone. You will lose the project's respository and all conent: issues, merge requests, etc.",
    ),
  },
};
</script>

<template>
  <shared-delete-button v-bind="{ confirmPhrase, formPath }">
    <template #modal-body>
      <gl-alert class="gl-mb-5" variant="danger" :dismissible="false">
        <template>
          <h4 class="gl-alert-title gl-text-red-500">{{ $options.strings.alertTitle }}</h4>
          <span v-html="alertBodyHtml"></span>
        </template>
      </gl-alert>

      <p>{{ $options.strings.modalBody }}</p>
    </template>
  </shared-delete-button>
</template>
