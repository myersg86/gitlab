# frozen_string_literal: true

module Projects
  module PerformanceMonitoring
    class DashboardsController < ::Projects::ApplicationController
      include BlobHelper

      before_action :check_repository_available!
      before_action :validate_required_params!

      rescue_from ActionController::ParameterMissing do |exception|
        respond_error(http_status: :bad_request, message: "Request parameter #{exception.param} is missing.")
      end

      USER_DASHBOARDS_DIR = ::Metrics::Dashboard::ProjectDashboardService::DASHBOARD_ROOT

      def create
        result = ::Metrics::Dashboard::CloneDashboardService.new(project, current_user, dashboard_params).execute

        if result[:status] == :success
          respond_success(result)
        else
          respond_error(result)
        end
      end

      private

      def respond_success(result)
        respond_to do |format|
          format.json { render status: result.delete(:http_status), json: result }
        end
      end

      def respond_error(result)
        respond_to do |format|
          format.json { render json: { error: result[:message] }, status: result[:http_status] }
        end
      end

      def validate_required_params!
        params.require(%i(branch file_name dashboard commit_message))
      end

      def new_dashboard_path
        File.join(USER_DASHBOARDS_DIR, params[:file_name])
      end

      def redirect_safe_branch_name
        repository.find_branch(params[:branch]).name
      end

      def dashboard_params
        params.permit(%i(branch file_name dashboard commit_message)).to_h
      end
    end
  end
end
