<script>
import { mapState, mapActions } from 'vuex';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import UserSelect from './multi_user_select.vue';
import GroupSelect from './multi_group_select.vue';

const approvalsHelp = s__(
  'ApprovalSettings|Set number of approvals required before open merge requests can be merged',
);

const overrideApproversHelp = s__(
  'ApprovalSettings|Can override approvers and approvals required per merge request',
);

const resetApprovalsHelp = s__(
  'ApprovalSettings|Remove all approvals in a merge request when new commits are pushed to its source branch',
);

export default {
  name: 'ApprovalSettings',
  components: {
    UserSelect,
    GroupSelect,
    LoadingIcon,
    LoadingButton,
  },
  computed: {
    ...mapState(['settings', 'isLoading', 'isSaving', 'projectId']),
    overridingApproversPerMergeRequest: {
      get() {
        return !this.settings.disable_overriding_approvers_per_merge_request;
      },
      set(value) {
        this.settings.disable_overriding_approvers_per_merge_request = !value;
      },
    },
    translations() {
      return {
        approvalsHelp,
        overrideApproversHelp,
        resetApprovalsHelp,
      };
    },
  },
  methods: {
    ...mapActions(['updateUsers', 'updateGroups', 'saveSettings']),
    onSubmit() {
      if (this.isSaving) {
        return Promise.resolve();
      }
      return this.saveSettings()
        .then(() => {
          createFlash(s__('ApprovalSettings|The approval settings were saved.'), 'notice');
        })
        .catch(error => {
          createFlash(s__('ApprovalSettings|Saving settings failed. Please try again.'));
          throw error;
        });
    },
  },
};
</script>

<template>
  <div
    class="approval-settings"
  >
    <loading-icon v-if="isLoading"/>
    <form
      v-if="!isLoading"
      @submit.prevent.stop="onSubmit"
    >
      <div class="form-group">
        <label
          class="label-light"
        >
          {{ s__('ApprovalSettings|Approvers') }}
        </label>
      </div>
      <div class="form-group">
        <label for="approvers-select">
          {{ s__('ApprovalSettings|Choose approvers from users') }}
        </label>
        <user-select
          id="approvers-select"
          :users="settings.approvers"
          :project-id="projectId"
          :disabled="isSaving"
          @select="updateUsers"
        />
        <label for="approver-groups-select">
          {{ s__('ApprovalSettings|Choose approvers from groups') }}
        </label>
        <group-select
          id="approver-groups-select"
          :groups="settings.approver_groups"
          :project-id="projectId"
          :disabled="isSaving"
          @select="updateGroups"
        />
      </div>
      <div class="form-group">
        <label
          for="approvals-before-merge"
          class="label-light"
        >
          {{ s__('ApprovalSettings|Approvals required') }}
        </label>
        <input
          type="number"
          min="0"
          step="1"
          class="form-control"
          id="approvals-before-merge"
          v-model="settings.approvals_before_merge"
          aria-describedby="approvals-help"
          :disabled="isSaving"
        />
        <p
          id="approvals-help"
          class="form-text text-muted"
        >
          {{ translations.approvalsHelp }}
        </p>
      </div>
      <div class="form-group">
        <label
          for="approvals-before-merge"
          class="label-light"
        >
          {{ s__('ApprovalSettings|Advanced settings') }}
        </label>
        <div class="form-check">
          <input
            class="form-check-input"
            type="checkbox"
            v-model="overridingApproversPerMergeRequest"
            id="can-override-approvers"
            :disabled="isSaving"
          />
          <label
            class="form-check-label"
            for="can-override-approvers"
          >
            {{ translations.overrideApproversHelp }}
          </label>
        </div>
        <div class="form-check">
          <input
            class="form-check-input"
            type="checkbox"
            v-model="settings.reset_approvals_on_push"
            id="reset-approvals-on-push"
            :disabled="isSaving"
          />
          <label
            class="form-check-label"
            for="reset-approvals-on-push"
          >
            {{ translations.resetApprovalsHelp }}
          </label>
        </div>
      </div>
      <loading-button
        type="submit"
        container-class="btn btn-success"
        :disabled="isSaving"
        :loading="isSaving"
        :label="s__('Save changes')"
      />
    </form>
  </div>
</template>
