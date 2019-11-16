<script>
import { omit } from 'underscore';
import { GlEmptyState, GlPagination, GlSkeletonLoading } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import flash from '~/flash';
import { scrollToElement, urlParamsToObject } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import initManualOrdering from '~/manual_ordering';
import Issuable from './issuable.vue';
import {
  sortOrderMap,
  RELATIVE_POSITION,
  PAGE_SIZE,
  PAGE_SIZE_MANUAL,
  LOADING_LIST_ITEMS_LENGTH,
} from '../constants';
import issueableEventHub from '../eventhub';
import store from '../store';

export default {
  LOADING_LIST_ITEMS_LENGTH,
  store,
  components: {
    GlEmptyState,
    GlPagination,
    GlSkeletonLoading,
    Issuable,
  },
  props: {
    canBulkEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    createIssuePath: {
      type: String,
      required: false,
      default: '',
    },
    emptySvgPath: {
      type: String,
      required: false,
      default: '',
    },
    endpoint: {
      type: String,
      required: true,
    },
    sortKey: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState(['issuables', 'loading', 'totalItems', 'page', 'isBulkEditing', 'selection', 'filters']),
    ...mapGetters(['allIssuablesSelected', 'isSelectedIssuable']),
    emptyState() {
      if (this.issuables.length) {
        return {}; // Empty state shouldn't be shown here
      } else if (this.hasFilters) {
        return {
          title: __('Sorry, your filter produced no results'),
          description: __('To widen your search, change or remove filters above'),
        };
      } else if (this.filters.state === 'opened') {
        return {
          title: __('There are no open issues'),
          description: __('To keep this project going, create a new issue'),
          primaryLink: this.createIssuePath,
          primaryText: __('New issue'),
        };
      } else if (this.filters.state === 'closed') {
        return {
          title: __('There are no closed issues'),
        };
      }

      return {
        title: __('There are no issues to show'),
        description: __(
          'The Issue Tracker is the place to add things that need to be improved or solved in a project. You can register or sign in to create issues for this project.',
        ),
      };
    },
    hasFilters() {
      const ignored = ['utf8', 'state', 'scope', 'order_by', 'sort'];
      return Object.keys(omit(this.filters, ignored)).length > 0;
    },
    isManualOrdering() {
      return this.sortKey === RELATIVE_POSITION;
    },
    itemsPerPage() {
      return this.isManualOrdering ? PAGE_SIZE_MANUAL : PAGE_SIZE;
    },
    baseUrl() {
      return window.location.href.replace(/(\?.*)?(#.*)?$/, '');
    },
  },
  watch: {
    selection() {
      // We need to call nextTick here to wait for all of the boxes to be checked and rendered
      // before we query the dom in issuable_bulk_update_actions.js.
      this.$nextTick(() => {
        issueableEventHub.$emit('issuables:updateBulkEdit');
      });
    },
    issuables() {
      this.$nextTick(() => {
        initManualOrdering();
      });
    },
  },
  mounted() {
    if (this.canBulkEdit) {
      this.unsubscribeToggleBulkEdit = issueableEventHub.$on('issuables:toggleBulkEdit', val => {
        this.setBulkEditing(val);
      });
    }
    this.fetchIssuables();
  },
  beforeDestroy() {
    issueableEventHub.$off('issuables:toggleBulkEdit');
  },
  methods: {
    ...mapActions([
      'setBulkEditing',
      'getIssuables',
      'clearSelection',
      'selectAllOnPaginatedPage',
      'setSelectId',
      'setFilters',
    ]),
    generateParams(pageToFetch) {
      return {
        ...this.filters,
        with_labels_details: true,
        page: pageToFetch || this.page,
        per_page: this.itemsPerPage,
      };
    },
    fetchIssuables(pageToFetch) {
      this.clearSelection();

      this.setFilters({
        queryObj: this.getQueryObject(),
        sort: sortOrderMap[this.sortKey],
      });


      return this.getIssuables({
        endpoint: this.endpoint,
        params: this.generateParams(pageToFetch),
      });
    },
    getQueryObject() {
      return urlParamsToObject(window.location.search);
    },
    onPaginate(newPage) {
      if (newPage === this.page) return;

      scrollToElement('#content-body');
      this.fetchIssuables(newPage);
    },
    onSelectAll() {
      if (this.allIssuablesSelected) {
        this.clearSelection();
      } else {
        this.selectAllOnPaginatedPage();
      }
    },
    onSelectIssuable({ issuable, selected }) {
      if (!this.canBulkEdit) return;

      this.setSelectId({ id: issuable.id, selected });
    },
  },
};
</script>

<template>
  <ul v-if="loading" class="content-list">
    <li v-for="n in $options.LOADING_LIST_ITEMS_LENGTH" :key="n" class="issue">
      <gl-skeleton-loading />
    </li>
  </ul>
  <div v-else-if="issuables.length">
    <div v-if="isBulkEditing" class="issue px-3 py-3 border-bottom border-light">
      <input type="checkbox" :checked="allIssuablesSelected" class="mr-2" @click="onSelectAll" />
      <strong>{{ __('Select all') }}</strong>
    </div>
    <ul
      class="content-list issuable-list issues-list"
      :class="{ 'manual-ordering': isManualOrdering }"
    >
      <issuable
        v-for="issuable in issuables"
        :key="issuable.id"
        class="pr-3"
        :class="{ 'user-can-drag': isManualOrdering }"
        :issuable="issuable"
        :is-bulk-editing="isBulkEditing"
        :selected="isSelectedIssuable(issuable.id)"
        :base-url="baseUrl"
        @select="onSelectIssuable"
      />
    </ul>
    <div class="mt-3">
      <gl-pagination
        v-if="totalItems"
        :value="page"
        :per-page="itemsPerPage"
        :total-items="totalItems"
        class="justify-content-center"
        @input="onPaginate"
      />
    </div>
  </div>
  <gl-empty-state
    v-else
    :title="emptyState.title"
    :description="emptyState.description"
    :svg-path="emptySvgPath"
    :primary-button-link="emptyState.primaryLink"
    :primary-button-text="emptyState.primaryText"
  />
</template>
