<script>
import { GlModal } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlModal,
  },
  props: {
    actionUrl: {
      type: String,
      required: true,
    },
    confirmWithPassword: {
      type: Boolean,
      required: true,
    },
    username: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      enteredPassword: '',
      enteredUsername: '',
    };
  },
  computed: {
    csrfToken() {
      return csrf.token;
    },
    inputLabel() {
      let confirmationValue;
      if (this.confirmWithPassword) {
        confirmationValue = __('password');
      } else {
        confirmationValue = __('username');
      }

      confirmationValue = `<code>${confirmationValue}</code>`;

      return sprintf(
        s__('Profiles|Type your %{confirmationValue} to confirm:'),
        { confirmationValue },
        false,
      );
    },
    primaryProps() {
      return {
        text: 'Delete account',
      };
    },
    cancelProps() {
      return {
        text: 'Cancel',
      };
    },
  },
  methods: {
    canSubmit() {
      if (this.confirmWithPassword) {
        return this.enteredPassword !== '';
      }

      return this.enteredUsername === this.username;
    },
    onSubmit() {
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="delete-account-modal"
    title="Profiles"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @submit="onSubmit"
  >
    <template #body="props">
      <p v-html="props.text"></p>

      <form ref="form" :action="actionUrl" method="post">
        <input type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />

        <p id="input-label" v-html="inputLabel"></p>

        <input
          v-if="confirmWithPassword"
          v-model="enteredPassword"
          name="password"
          class="form-control"
          type="password"
          data-qa-selector="password_confirmation_field"
          aria-labelledby="input-label"
        />
        <input
          v-else
          v-model="enteredUsername"
          name="username"
          class="form-control"
          type="text"
          aria-labelledby="input-label"
        />
      </form>
    </template>
  </gl-modal>
</template>
