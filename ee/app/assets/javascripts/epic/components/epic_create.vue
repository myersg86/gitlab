<script>
import { mapState, mapActions } from 'vuex';
import {
  GlForm,
  GlFormInput,
  GlFormCheckbox,
  GlIcon,
  GlButton,
  GlTooltipDirective,
  GlDeprecatedButton,
} from '@gitlab/ui';

import { __ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlFormCheckbox,
    GlIcon,
    GlDeprecatedButton,
    GlButton,
    GlForm,
    GlFormInput,
  },
  directives: {
    autofocusonshow,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    alignRight: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['newEpicTitle', 'newEpicConfidential', 'epicCreateInProgress']),
    buttonLabel() {
      return this.epicCreateInProgress ? __('Creating epic') : __('Create epic');
    },
    isEpicCreateDisabled() {
      return !this.newEpicTitle.length;
    },
    epicTitle: {
      set(value) {
        this.setEpicCreateTitle({
          newEpicTitle: value,
        });
      },
      get() {
        return this.newEpicTitle;
      },
    },
    epicConfidential: {
      set(value) {
        this.setEpicCreateConfidential({
          newEpicConfidential: value,
        });
      },
      get() {
        return this.newEpicConfidential;
      },
    },
  },
  methods: {
    ...mapActions(['setEpicCreateTitle', 'createEpic', 'setEpicCreateConfidential']),
  },
};
</script>

<template>
  <div class="dropdown epic-create-dropdown">
    <gl-deprecated-button variant="success" class="qa-new-epic-button" data-toggle="dropdown">
      {{ __('New epic') }}
    </gl-deprecated-button>

    <div :class="{ 'dropdown-menu-right': alignRight }" class="dropdown-menu">
      <gl-form>
        <gl-form-input
          ref="epicTitleInput"
          v-model="epicTitle"
          v-autofocusonshow
          :disabled="epicCreateInProgress"
          :placeholder="__('Title')"
          type="text"
          class="form-control"
          data-qa-selector="epic_title_field"
          @keyup.enter.exact="createEpic"
        />
        <gl-form-checkbox
          v-if="glFeatures.confidentialEpics"
          v-model="epicConfidential"
          class="mt-3 mb-3 mr-0"
          ><span> {{ __('Make this epic confidential') }} </span>
          <span
            v-gl-tooltip.viewport.top.hover
            :title="
              __(
                'This epic and its child elements will only be visible to team members with at minimum Reporter access.',
              )
            "
            :aria-label="
              __(
                'This epic and its child elements will only be visible to team members with at minimum Reporter access.',
              )
            "
          >
            <gl-icon name="question" :size="12"
          /></span>
        </gl-form-checkbox>
        <gl-button
          :disabled="isEpicCreateDisabled"
          :loading="epicCreateInProgress"
          category="primary"
          variant="success"
          class="prepend-top-10 qa-create-epic-button"
          @click.stop="createEpic"
          >{{ buttonLabel }}</gl-button
        >
      </gl-form>
    </div>
  </div>
</template>
