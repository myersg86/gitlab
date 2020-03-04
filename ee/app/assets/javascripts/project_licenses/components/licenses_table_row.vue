<script>
import { GlLink, GlSkeletonLoading } from '@gitlab/ui';
import LicenseComponentLinks from './license_component_links.vue';
import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/reports/constants';

export default {
  name: 'LicensesTableRow',
  components: {
    IssueStatusIcon,
    LicenseComponentLinks,
    GlLink,
    GlSkeletonLoading,
  },
  props: {
    license: {
      type: Object,
      required: false,
      default: null,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    icons() {
      return {
        allowed: STATUS_SUCCESS,
        denied: STATUS_FAILED,
        unclassified: STATUS_NEUTRAL,
      };
    },
    iconStatus() {
      return this.icons[this.license.classification];
    },
  },
};
</script>

<template>
  <div class="gl-responsive-table-row flex-md-column align-items-md-stretch px-2">
    <gl-skeleton-loading
      v-if="isLoading"
      :lines="1"
      class="d-flex flex-column justify-content-center h-auto"
    />

    <div
      v-else
      class="d-md-flex align-items-baseline js-license-row"
      :data-spdx-id="license.spdx_identifier"
    >
      <!-- Name-->
      <div class="table-section section-30 section-wrap pr-md-3">
        <div class="table-mobile-header" role="rowheader">
          {{ s__('Licenses|Name') }}
        </div>
        <div class="table-mobile-content">
          <gl-link v-if="license.url" :href="license.url" target="_blank">{{
            license.name
          }}</gl-link>
          <template v-else>{{ license.name }}</template>
        </div>
      </div>

      <!-- Component -->
      <div class="table-section section-50 section-wrap pr-md-2">
        <div class="table-mobile-header" role="rowheader">{{ s__('Licenses|Component') }}</div>
        <div class="table-mobile-content">
          <license-component-links :components="license.components" :title="license.name" />
        </div>
      </div>

      <!-- Policy -->
      <div class="table-section section-20 section-wrap pr-md-1">
        <div class="table-mobile-header" role="rowheader">{{ s__('Licenses|Classification') }}</div>
        <div
          class="table-mobile-content text-capitalize d-flex align-items-center justify-content-end justify-content-md-start status"
        >
          <issue-status-icon :status="iconStatus" />
          {{ license.classification }}
        </div>
      </div>
    </div>
  </div>
</template>
