# frozen_string_literal: true

module Gitlab
  class DeployKeyAccess < UserAccess
    extend Gitlab::Cache::RequestCache

    request_cache_key do
      [user&.id, deploy_key&.id, project&.id]
    end

    attr_reader :deploy_key

    def initialize(deploy_key, project: nil)
      @deploy_key = deploy_key
      @user = deploy_key&.user
      @project = project
    end

    request_cache def can_push_to_branch?(ref)
      if protected?(ProtectedBranch, project, ref)
        protected_branch_accessible_to?(ref, action: :push)
      else
        true
      end
    end

    private

    request_cache def git_access_check
      true
    end

    def protected_branch_accessible_to?(ref, action:)
      ProtectedBranch.protected_ref_accessible_to?(
        ref, deploy_key,
        project: project,
        action: action,
        protected_refs: project.protected_branches)
    end
  end
end
