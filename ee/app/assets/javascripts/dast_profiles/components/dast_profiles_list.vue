<script>
import {
  GlAlert,
  GlButton,
  GlIcon,
  GlSkeletonLoading,
  GlTable,
  GlTooltipDirective,
  GlTruncate,
} from '@gitlab/ui';

export default {
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlSkeletonLoading,
    GlTable,
    GlTruncate,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    profiles: {
      type: Array,
      required: true,
    },
    // @TODO - test behaviour
    hasError: {
      type: Boolean,
      required: false,
      default: false,
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
  data() {
    return {
      isErrorDismissed: false,
    };
  },
  computed: {
    hasProfiles() {
      return this.profiles.length > 0;
    },
    isLoadingInitialProfiles() {
      return this.isLoading && !this.hasProfiles;
    },
  },
  tableFields: [
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
    <div v-if="isLoadingInitialProfiles || hasProfiles || hasError">
      <gl-table
        :busy="isLoadingInitialProfiles"
        stacked="sm"
        :fields="$options.tableFields"
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
          <span
            v-gl-tooltip.hover
            :title="
              s__(
                'DastProfiles|Edit feature will come soon. Please create a new profile if changes needed',
              )
            "
          >
            <gl-button disabled>{{ __('Edit') }}</gl-button>
          </span>
        </template>

        <template #table-busy>
          <gl-skeleton-loading
            v-for="i in profilesPerPage"
            :key="i"
            class="m-2 js-skeleton-loader"
            :lines="2"
          />
        </template>

        <template v-if="hasError && !isErrorDismissed" #bottom-row>
          <td>
            <gl-alert class="gl-my-4" variant="danger" @dismiss="isErrorDismissed = true">
              {{
                s__(
                  'DastProfiles|Error fetching the profiles list. Please check your network connection and try again.',
                )
              }}
            </gl-alert>
          </td>
        </template>
      </gl-table>

      <p v-if="hasMorePages" class="gl-display-flex gl-justify-content-center">
        <gl-button :loading="isLoading && !hasError" @click="$emit('loadMorePages')">{{
          __('Load more')
        }}</gl-button>
      </p>
    </div>

    <p v-else class="gl-my-4">
      {{ s__('DastProfiles|No profiles created yet') }}
    </p>
  </section>
</template>
