<script>
import { GlButton, GlIcon, GlSkeletonLoading, GlTable, GlTruncate } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlIcon,
    GlSkeletonLoading,
    GlTable,
    GlTruncate,
  },
  props: {
    profiles: {
      type: Array,
      required: true,
    },
    // @TODO - test behaviour
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    // @TODO - test behaviour
    profilesPerPage: {
      type: Number,
      required: false,
      default: 10,
    },
    hasMorePages: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasProfiles() {
      return this.profiles.length > 0;
    },
    isLoadingInitialProfiles() {
      return this.isLoading && !this.hasProfiles;
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
    <div v-if="isLoadingInitialProfiles || hasProfiles">
      <gl-table
        :busy="isLoadingInitialProfiles"
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
          <gl-button>{{ __('Edit') }}</gl-button>
        </template>

        <template #table-busy>
          <gl-skeleton-loading
            v-for="i in profilesPerPage"
            :key="i"
            class="m-2 js-skeleton-loader"
            :lines="2"
          />
        </template>
      </gl-table>
      <p v-if="hasMorePages" class="gl-display-flex gl-justify-content-center">
        <gl-button :loading="isLoading" @click="$emit('loadMorePages')">{{
          __('Load more')
        }}</gl-button>
      </p>
    </div>
    <p v-else>{{ s__('DastProfiles|No profiles created yet') }}</p>
  </section>
</template>
