<script>
import { mapActions, mapState } from 'vuex';
import { GlDeprecatedButton, GlFormCheckbox, GlSkeletonLoading } from '@gitlab/ui';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import Icon from '~/vue_shared/components/icon.vue';
import VulnerabilityActionButtons from './vulnerability_action_buttons.vue';
import VulnerabilityIssueLink from './vulnerability_issue_link.vue';
import { DASHBOARD_TYPES } from '../store/constants';

export default {
  name: 'SecurityDashboardTableRow',
  components: {
    GlDeprecatedButton,
    GlFormCheckbox,
    GlSkeletonLoading,
    Icon,
    SeverityBadge,
    VulnerabilityActionButtons,
    VulnerabilityIssueLink,
  },
  props: {
    vulnerability: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['dashboardType']),
    ...mapState('vulnerabilities', ['selectedVulnerabilities']),
    severity() {
      return this.vulnerability.severity || ' ';
    },
    vulnerabilityNamespace() {
      const { project, location } = this.vulnerability;
      if (this.dashboardType === DASHBOARD_TYPES.GROUP) {
        return project && project.full_name;
      }
      return location && (location.image || location.file || location.path);
    },
    isDismissed() {
      return Boolean(this.vulnerability.dismissal_feedback);
    },
    hasIssue() {
      return Boolean(
        this.vulnerability.issue_feedback && this.vulnerability.issue_feedback.issue_iid,
      );
    },
    canDismissVulnerability() {
      const path = this.vulnerability.create_vulnerability_feedback_dismissal_path;
      return Boolean(path);
    },
    canCreateIssue() {
      const path = this.vulnerability.create_vulnerability_feedback_issue_path;
      return Boolean(path) && !this.hasIssue;
    },
    isSelected() {
      return Boolean(this.selectedVulnerabilities[this.vulnerability.id]);
    },
  },
  methods: {
    ...mapActions('vulnerabilities', ['openModal', 'selectVulnerability', 'deselectVulnerability']),
    toggleVulnerability() {
      if (this.isSelected) {
        return this.deselectVulnerability(this.vulnerability);
      }
      return this.selectVulnerability(this.vulnerability);
    },
  },
};
</script>

<template>
  <div
    class="gl-responsive-table-row vulnerabilities-row p-2"
    :class="{ dismissed: isDismissed, 'gl-bg-blue-50': isSelected }"
  >
    <div class="table-section section-5">
      <gl-form-checkbox
        :checked="isSelected"
        :inline="true"
        class="my-0 ml-1 mr-3"
        @change="toggleVulnerability"
      />
    </div>

    <div class="table-section section-15">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Severity') }}</div>
      <div class="table-mobile-content">
        <severity-badge :severity="severity" class="text-right text-md-left" />
      </div>
    </div>

    <div class="table-section flex-grow-1">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Vulnerability') }}</div>
      <div
        class="table-mobile-content gl-white-space-normal"
        data-qa-selector="vulnerability_info_content"
      >
        <gl-skeleton-loading v-if="isLoading" class="mt-2 js-skeleton-loader" :lines="2" />
        <template v-else>
          <gl-deprecated-button
            ref="vulnerability-title"
            class="d-inline gl-reset-line-height gl-reset-text-align gl-white-space-normal"
            variant="blank"
            @click="openModal({ vulnerability })"
            >{{ vulnerability.name }}</gl-deprecated-button
          >
          <template v-if="isDismissed">
            <icon
              v-show="vulnerability.dismissal_feedback.comment_details"
              name="comment"
              class="text-warning vertical-align-middle"
            />
            <span class="vertical-align-middle text-uppercase">{{
              s__('vulnerability|dismissed')
            }}</span>
          </template>
          <vulnerability-issue-link
            v-if="hasIssue"
            class="text-nowrap"
            :issue="vulnerability.issue_feedback"
            :project-name="vulnerability.project.name"
          />
          <br />
          <small v-if="vulnerabilityNamespace" class="gl-text-gray-700 gl-word-break-all">
            {{ vulnerabilityNamespace }}
          </small>
        </template>
      </div>
    </div>

    <div class="table-section section-20">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Actions') }}</div>
      <div class="table-mobile-content action-buttons d-flex justify-content-end">
        <vulnerability-action-buttons
          v-if="!isLoading"
          :vulnerability="vulnerability"
          :can-create-issue="canCreateIssue"
          :can-dismiss-vulnerability="canDismissVulnerability"
          :is-dismissed="isDismissed"
        />
      </div>
    </div>
  </div>
</template>
