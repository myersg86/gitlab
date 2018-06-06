<script>
import { mapState, mapActions } from 'vuex';
import UserSelect from './multi_user_select.vue';

export default {
  name: 'ApprovalSettings',
  components: {
    UserSelect,
  },
  computed: {
    ...mapState(['settings', 'isLoading', 'projectId']),
    overridingApproversPerMergeRequest: {
      get() {
        return !this.settings.disable_overriding_approvers_per_merge_request;
      },
      set(value) {
        this.settings.disable_overriding_approvers_per_merge_request = !value;
      },
    },
  },
  methods: {
    ...mapActions(['updateUsers']),
  },
};
</script>

<template>
  <div
    class="approval-settings"
    v-if="!isLoading"
  >
    <div class="form-group">
      <label
        class="label-light"
      >
        Approvers
      </label>
    </div>
    <div class="form-group">
      <label for="approvers-select">
        Choose approvers from users
      </label>
      <user-select
        id="approvers-select"
        :users="settings.approvers"
        :project-id="projectId"
        @select="updateUsers"
      />
    </div>
    <div class="form-group">
      <label
        for="approvals-before-merge"
        class="label-light"
      >
        Approvals required
      </label>
      <input
        type="number"
        min="0"
        step="1"
        class="form-control"
        id="approvals-before-merge"
        v-model="settings.approvals_before_merge"
        aria-describedby="approvals-help"
      />
      <p
        id="approvals-help"
        class="form-text text-muted"
      >
        Set number of approvals required before open merge requests can be merged
      </p>
    </div>
    <div class="form-group">
      <label
        for="approvals-before-merge"
        class="label-light"
      >
        Advanced settings
      </label>
      <div class="form-check">
        <input
          class="form-check-input"
          type="checkbox"
          v-model="overridingApproversPerMergeRequest"
          id="can-override-approvers"
        />
        <label
          class="form-check-label"
          for="can-override-approvers"
        >
          Can override approvers and approvals required per merge request
        </label>
      </div>
      <div class="form-check">
        <input
          class="form-check-input"
          type="checkbox"
          v-model="settings.reset_approvals_on_push"
          id="reset-approvals-on-push"
        />
        <label
          class="form-check-label"
          for="reset-approvals-on-push"
        >
          Remove all approvals in a merge request when new commits are pushed to its source branch
        </label>
      </div>
    </div>
    <pre>{{ JSON.stringify(settings,null,2) }}</pre>
  </div>
</template>
