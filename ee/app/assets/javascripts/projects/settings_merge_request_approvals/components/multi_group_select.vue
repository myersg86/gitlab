<script>
import $ from 'jquery';
import GroupsSelect from '~/groups_select';

export default {
  props: {
    groups: {
      type: Array,
      required: true,
    },
    projectId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  mounted() {
    new GroupsSelect();
    const select = $(this.$refs.groupSelect);
    select.on('change', e => {
      this.$emit('select', e);
    });
    select.select2('val', this.groups.map(user => user.id));
  },
};
</script>

<template>
  <input
    ref="groupSelect"
    type="hidden"
    value=""
    multiple="multiple"
    data-all-available="true"
    class="input-large ajax-groups-select multiselect multiselect"
  >
  <!--    data-project="{&quot;id&quot;:8,&quot;name&quot;:&quot;Html5 Boilerplate&quot;,&quot;path&quot;:&quot;html5-boilerplate&quot;,&quot;description&quot;:&quot;Unde ut porro consequatur commodi omnis dolores esse.&quot;,&quot;created_at&quot;:&quot;2018-04-17T10:28:21.253Z&quot;,&quot;updated_at&quot;:&quot;2018-06-01T07:22:42.706Z&quot;,&quot;creator_id&quot;:1,&quot;namespace_id&quot;:7,&quot;last_activity_at&quot;:&quot;2018-05-15T07:01:18.702Z&quot;,&quot;import_url&quot;:&quot;https://github.com/h5bp/html5-boilerplate.git&quot;,&quot;visibility_level&quot;:20,&quot;archived&quot;:false,&quot;avatar&quot;:{&quot;url&quot;:null},&quot;import_status&quot;:&quot;finished&quot;,&quot;merge_requests_template&quot;:&quot;&quot;,&quot;star_count&quot;:0,&quot;merge_requests_rebase_enabled&quot;:false,&quot;import_type&quot;:null,&quot;import_source&quot;:null,&quot;approvals_before_merge&quot;:1,&quot;reset_approvals_on_push&quot;:true,&quot;merge_requests_ff_only_enabled&quot;:false,&quot;issues_template&quot;:null,&quot;mirror&quot;:false,&quot;mirror_last_update_at&quot;:null,&quot;mirror_last_successful_update_at&quot;:null,&quot;mirror_user_id&quot;:null,&quot;import_error&quot;:null,&quot;ci_id&quot;:null,&quot;shared_runners_enabled&quot;:true,&quot;runners_token&quot;:&quot;BVbfLrUSBaF96zHQ5XTm&quot;,&quot;build_coverage_regex&quot;:null,&quot;build_allow_git_fetch&quot;:true,&quot;build_timeout&quot;:3600,&quot;mirror_trigger_builds&quot;:false,&quot;pending_delete&quot;:false,&quot;public_builds&quot;:true,&quot;last_repository_check_failed&quot;:false,&quot;last_repository_check_at&quot;:&quot;2018-05-15T07:20:09.190Z&quot;,&quot;container_registry_enabled&quot;:true,&quot;only_allow_merge_if_pipeline_succeeds&quot;:false,&quot;has_external_issue_tracker&quot;:false,&quot;repository_storage&quot;:&quot;default&quot;,&quot;repository_read_only&quot;:null,&quot;request_access_enabled&quot;:false,&quot;has_external_wiki&quot;:false,&quot;ci_config_path&quot;:null,&quot;lfs_enabled&quot;:null,&quot;only_allow_merge_if_all_discussions_are_resolved&quot;:false,&quot;repository_size_limit&quot;:null,&quot;printing_merge_request_link_enabled&quot;:true,&quot;auto_cancel_pending_pipelines&quot;:&quot;enabled&quot;,&quot;service_desk_enabled&quot;:null,&quot;import_jid&quot;:&quot;bc3fc5fa0ff17dc7cf41c1ee&quot;,&quot;delete_error&quot;:null,&quot;last_repository_updated_at&quot;:&quot;2018-04-17T10:28:21.253Z&quot;,&quot;disable_overriding_approvers_per_merge_request&quot;:false,&quot;storage_version&quot;:null,&quot;resolve_outdated_diff_discussions&quot;:false,&quot;remote_mirror_available_overridden&quot;:null,&quot;only_mirror_protected_branches&quot;:true,&quot;pull_mirror_available_overridden&quot;:null,&quot;jobs_cache_index&quot;:null,&quot;mirror_overwrites_diverged_branches&quot;:null,&quot;external_authorization_classification_label&quot;:null,&quot;external_webhook_token&quot;:null,&quot;pages_https_only&quot;:false}"-->
</template>
