<script>
import { mapState } from 'vuex';
import { GlFormCheckbox } from '@gitlab/ui';
import store from '~/boards/stores';

export default {
  store,
  components: {
    GlFormCheckbox,
  },
  data() {
    return {
      options: {},
    };
  },
  computed: {
    ...mapState(['configurationOptions']),
  },
  mounted() {
    this.options = { ...this.configurationOptions };
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <label class="form-section-title label-bold media-body">
      {{ __('Board configuration options') }}
    </label>

    <gl-form-checkbox v-model="options.hideLabels">
      {{ __('Hide labels') }}
      <template #help>
        {{ __('Labels on issues will be hidden for all users of this board') }}
      </template>
    </gl-form-checkbox>

    <gl-form-checkbox v-model="options.hideOpenList">
      {{ __('Hide the Open list') }}
    </gl-form-checkbox>

    <gl-form-checkbox v-model="options.hideClosedList">
      {{ __('Hide the Closed list') }}
    </gl-form-checkbox>
  </div>
</template>
