<script>
import { __ } from '~/locale';
import MergeRequestsGrid from './merge_requests/grid.vue'
import EmptyState from './empty_state.vue';
import Pagination from './pagination.vue';

export default {
  name: 'ComplianceDashboard',
  components: {
    MergeRequestsGrid,
    EmptyState,
    Pagination,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    mergeRequests: {
      type: Array,
      required: true,
    },
    isLastPage: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasMergeRequests() {
      return this.mergeRequests.length > 0;
    },
  },
  strings: {
    heading: __('Compliance Dashboard'),
    subheading: __('Here you will find recent merge request activity'),
  },
};
</script>

<template>
  <div v-if="hasMergeRequests" class="compliance-dashboard">
    <header class="gl-my-5">
      <h4>{{ $options.strings.heading }}</h4>
      <p>{{ $options.strings.subheading }}</p>
    </header>

    <MergeRequestsGrid :merge-requests="mergeRequests"/>

    <pagination :is-last-page="isLastPage" />
  </div>
  <empty-state v-else :image-path="emptyStateSvgPath" />
</template>
