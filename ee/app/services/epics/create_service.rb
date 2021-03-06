# frozen_string_literal: true

module Epics
  class CreateService < Epics::BaseService
    def execute
      set_date_params
      params.extract!(:confidential) unless ::Feature.enabled?(:confidential_epics, group)

      epic = group.epics.new
      create(epic)
    end

    private

    def before_create(epic)
      epic.move_to_start if epic.parent

      # current_user (defined in BaseService) is not available within run_after_commit block
      user = current_user
      epic.run_after_commit do
        NewEpicWorker.perform_async(epic.id, user.id)
      end
    end

    def set_date_params
      if params[:start_date_fixed] && params[:start_date_is_fixed]
        params[:start_date] = params[:start_date_fixed]
      end

      if params[:due_date_fixed] && params[:due_date_is_fixed]
        params[:end_date] = params[:due_date_fixed]
      end
    end
  end
end
