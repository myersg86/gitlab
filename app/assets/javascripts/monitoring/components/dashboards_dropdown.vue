<script>
import { mapActions } from 'vuex';
import {
  GlAlert,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import DuplicateDashboardForm from './duplicate_dashboard_form.vue';

const events = {
  selectDashboard: 'selectDashboard',
};

export default {
  components: {
    GlAlert,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlModal,
    DuplicateDashboardForm,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    allDashboards: {
      type: Array,
      required: true,
    },
    selectedDashboard: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    defaultBranch: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      alert: null,
      loading: false,
      form: {},
    };
  },
  computed: {
    isSystemDashboard() {
      return this.selectedDashboard.system_dashboard;
    },
    selectedDashboardText() {
      return this.selectedDashboard.display_name;
    },
  },
  methods: {
    ...mapActions('monitoringDashboard', ['duplicateSystemDashboard']),
    selectDashboard(dashboard) {
      this.$emit(events.selectDashboard, dashboard);
    },
    ok(event) {
      event.preventDefault();

      this.loading = true;
      this.alert = null;
      this.duplicateSystemDashboard(this.form)
        .then(() => {
          this.loading = false;
          this.alert = null;

          this.$refs.duplicateDashboardModal.hide();

          this.$emit(events.selectDashboard, {
            // TODO This should only happen if this is master or the default branch!
            // TODO This path or full dashboard object should be returned from the backend
            path: `.gitlab/dashboards/${this.form.fileName}`,
          });
        })
        .catch(error => {
          this.loading = false;
          this.alert = error;
        });
    },
    formChange(form) {
      this.form = form;
    },
  },
};
</script>
<template>
  <gl-dropdown
    class="mb-0 d-flex js-dashboards-dropdown"
    toggle-class="dropdown-menu-toggle"
    :text="selectedDashboardText"
  >
    <gl-dropdown-item
      v-for="dashboard in allDashboards"
      :key="dashboard.path"
      :active="dashboard.path === selectedDashboard.path"
      active-class="is-active"
      @click="selectDashboard(dashboard)"
    >
      {{ dashboard.display_name || dashboard.path }}
    </gl-dropdown-item>

    <template v-if="isSystemDashboard">
      <gl-dropdown-divider />

      <gl-modal
        ref="duplicateDashboardModal"
        modal-id="duplicateDashboardModal"
        title="Duplicate this dashboard"
        :ok-title="!loading ? s__('Metrics|Duplicate') : s__('Metrics|Saving...')"
        @ok="ok"
      >
        <gl-alert v-if="alert" class="mb-3" variant="danger" @dismiss="alert = null">
          {{ alert }}
        </gl-alert>
        <duplicate-dashboard-form
          :dashboard="selectedDashboard"
          :default-branch="defaultBranch"
          @change="formChange"
        />
      </gl-modal>

      <gl-dropdown-item ref="duplicateDashboardItem" v-gl-modal="'duplicateDashboardModal'">
        {{ s__('Metrics|Duplicate dashboard') }}
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
