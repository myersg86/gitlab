<script>
import { GlButton, GlTable, GlTruncate, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlIcon,
    GlTable,
    GlTruncate,
  },
  props: {
    profiles: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasProfiles() {
      return this.profiles.length > 0;
    },
  },
  fields: [
    {
      key: 'profileName',
    },
    {
      key: 'targetUrl',
    },
    {
      key: 'validationStatus',
    },
    {
      key: 'actions',
    },
  ],
};
</script>
<template>
  <section>
    <gl-table
      v-if="hasProfiles"
      stacked="sm"
      :fields="$options.fields"
      :items="profiles"
      :aria-label="s__('DastProfiles|Site Profiles')"
      thead-class="gl-display-none"
    >
      <template #cell(profileName)="{ value }">
        <strong>{{ value }}</strong>
      </template>
      <template #cell(targetUrl)="{ value }">
        <gl-truncate :text="value" />
      </template>
      <template #cell(validationStatus)="{ value }">
        <span>
          <gl-icon
            name="information-o"
            :size="16"
            class="gl-vertical-align-text-bottom gl-text-gray-600"
          />
          {{ value }}
        </span>
      </template>
      <template #cell(actions)>
        <gl-button>Edit</gl-button>
      </template>
    </gl-table>
    <p v-else>{{ s__('DastProfiles|No profiles created yet') }}</p>
  </section>
</template>
