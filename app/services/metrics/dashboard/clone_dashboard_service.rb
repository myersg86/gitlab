# frozen_string_literal: true

# Copies system dashboard definition in .yml file into designated
# .yml file inside `.gitlab/dashboards`
module Metrics
  module Dashboard
    class CloneDashboardService < ::BaseService
      ALLOWED_FILE_TYPE = '.yml'
      USER_DASHBOARDS_DIR = ::Metrics::Dashboard::ProjectDashboardService::DASHBOARD_ROOT
      DASHBOARD_TEMPLATES = {
        ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH => ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH
      }.freeze

      def execute
        return error('Not found', :not_found) unless dashboard_template
        return error('File name should have .yml extension.', :bad_request) unless target_file_type_valid?
        return error(%q(You can't commit to this project), :forbidden) unless push_authorized?
        return error("There was an error creating the dashboard, branch name is invalid.", :bad_request) unless valid_branch_name?
        return error("There was an error creating the dashboard, branch named: #{branch} already exists.", :bad_request) unless valid_branch? # temporary validation for first UI iteration

        result = ::Files::CreateService.new(project, current_user, dashboard_attrs).execute
        return wrap_error(result) unless result[:status] == :success

        repository.refresh_method_caches([:metrics_dashboard])
        success(result.merge(http_status: :created))
      end

      private

      def push_authorized?
        Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(branch)
      end

      def target_file_type_valid?
        File.extname(params[:file_name]).eql? ALLOWED_FILE_TYPE
      end

      def dashboard_template
        DASHBOARD_TEMPLATES[params[:dashboard]]
      end

      def branch
        params[:branch]
      end

      def dashboard_attrs
        {
          commit_message: commit_message,
          file_path: new_dashboard_path,
          file_content: new_dashboard_content,
          encoding: 'text',
          branch_name: branch,
          start_branch: repository.branch_exists?(branch) ? branch : project.default_branch
        }
      end

      def commit_message
        params[:commit_message] || "Create custom dashboard #{params[:file_name]}"
      end

      def new_dashboard_path
        File.join(USER_DASHBOARDS_DIR, params[:file_name])
      end

      def new_dashboard_content
        File.read(Rails.root.join(dashboard_template))
      end

      def repository
        @_repository ||= project.repository
      end

      def valid_branch?
        !repository.branch_exists?(branch) || project.default_branch == branch
      end

      def valid_branch_name?
        Gitlab::GitRefValidator.validate(branch)
      end

      def wrap_error(result)
        case result[:message]
        when 'A file with this name already exists'
          error("A file with #{params[:file_name]} already exists in #{branch} branch", :bad_request)
        else
          result
        end
      end
    end
  end
end

Metrics::Dashboard::CloneDashboardService.prepend_if_ee('EE::Metrics::Dashboard::CloneDashboardService')
