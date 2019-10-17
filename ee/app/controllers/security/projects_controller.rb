# frozen_string_literal: true

module Security
  class ProjectsController < ::Security::ApplicationController
    def index
      head :ok
    end

    def create
      result = add_projects(current_user, project_ids)

      render json: {
        added: result.added_project_ids,
        duplicate: result.duplicate_project_ids,
        invalid: result.invalid_project_ids
      }
    end

    def destroy
      head :ok
    end

    private

    def project_ids
      params.require(:project_ids)
    end

    def add_projects(current_user, project_ids)
      UsersSecurityDashboardProjects::CreateService.new(current_user).execute(project_ids)
    end
  end
end
