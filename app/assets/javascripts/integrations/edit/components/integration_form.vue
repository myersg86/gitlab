<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import eventHub from '../event_hub';

import OverrideDropdown from './override_dropdown.vue';
import ActiveToggle from './active_toggle.vue';
import JiraTriggerFields from './jira_trigger_fields.vue';
import JiraIssuesFields from './jira_issues_fields.vue';
import TriggerFields from './trigger_fields.vue';
import DynamicField from './dynamic_field.vue';

export default {
  name: 'IntegrationForm',
  components: {
    OverrideDropdown,
    ActiveToggle,
    JiraTriggerFields,
    JiraIssuesFields,
    TriggerFields,
    DynamicField,
    GlButton,
    GlLoadingIcon,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters(['currentKey', 'propsSource', 'isSavingOrTesting']),
    ...mapState(['adminState', 'override', 'isSaving', 'isTesting']),
    isEditable() {
      return this.propsSource.editable;
    },
    isJira() {
      return this.propsSource.type === 'jira';
    },
    showJiraIssuesFields() {
      return this.isJira && this.glFeatures.jiraIssuesIntegration;
    },
  },
  methods: {
    ...mapActions(['setOverride', 'setIsSaving', 'setIsTesting']),
    onSaveClick() {
      this.setIsSaving(true);
    },
    onTestClick() {
      this.setIsTesting(true);
      eventHub.$emit('testIntegration');
    },
  },
};
</script>

<template>
  <div>
    <override-dropdown
      v-if="adminState !== null"
      :inherit-from-id="adminState.id"
      :override="override"
      @change="setOverride"
    />
    <active-toggle
      v-if="propsSource.showActive"
      :key="`${currentKey}-active-toggle`"
      v-bind="propsSource.activeToggleProps"
    />
    <jira-trigger-fields
      v-if="isJira"
      :key="`${currentKey}-jira-trigger-fields`"
      v-bind="propsSource.triggerFieldsProps"
    />
    <trigger-fields
      v-else-if="propsSource.triggerEvents.length"
      :key="`${currentKey}-trigger-fields`"
      :events="propsSource.triggerEvents"
      :type="propsSource.type"
    />
    <dynamic-field
      v-for="field in propsSource.fields"
      :key="`${currentKey}-${field.name}`"
      v-bind="field"
    />
    <jira-issues-fields
      v-if="showJiraIssuesFields"
      :key="`${currentKey}-jira-issues-fields`"
      v-bind="propsSource.jiraIssuesProps"
    />
    <div v-if="isEditable" class="footer-block row-content-block">
      <gl-button
        category="primary"
        variant="success"
        type="submit"
        :disabled="isSavingOrTesting"
        data-qa-selector="save_changes_button"
        @click="onSaveClick"
      >
        <gl-loading-icon v-show="isSaving" inline color="dark" />
        {{ __('Save changes') }}
      </gl-button>
      <gl-button
        v-if="propsSource.canTest"
        :disabled="isSavingOrTesting"
        :href="propsSource.testPath"
        @click.prevent="onTestClick"
      >
        <gl-loading-icon v-show="isTesting" inline color="dark" />
        {{ __('Test settings') }}
      </gl-button>

      <gl-button class="btn-cancel" :href="propsSource.cancelPath">{{ __('Cancel') }}</gl-button>
    </div>
  </div>
</template>
