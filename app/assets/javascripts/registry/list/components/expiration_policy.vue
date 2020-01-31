<script>
import { GlIcon, GlButton } from '@gitlab/ui';

import ExpirationPolicyForm from '../../shared/components/expiration_policy_form.vue';

export default {
  components: {
    GlIcon,
    GlButton,
    ExpirationPolicyForm,
  },
  data() {
    return {
      settings: {},
      show: false,
    };
  },
  computed: {
    iconName() {
      return this.settings.enabled ? 'check-circle-filled' : 'canceled-circle';
    },
    iconClass() {
      return this.settings.enabled ? 'gl-text-green-700' : '';
    },
  },
  methods: {
    toggle() {
      this.show = !this.show;
    },
  },
};
</script>

<template>
  <div class="position-relative">
    <gl-button @click="toggle">
      <div class="d-flex justify-content-center align-items-center">
        <gl-icon class="mb-1" :name="iconName" :class="iconClass" />
        {{ __('Expiration policy') }}
        <gl-icon class="mb-1 ml-2" name="angle-down" />
      </div>
    </gl-button>
    <expiration-policy-form
      v-if="show"
      v-model="settings"
      label-cols="4"
      class="position-absolute gl-z-10 gl-w-xl gl-right-0"
      @submit="toggle"
      @reset="toggle"
    />
  </div>
</template>

<style></style>
