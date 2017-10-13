module Epics
  class UpdateService < ::BaseService
    def execute(epic)
      update(epic)
    end

    # we should use IssuableBaseService method after the differences with issuables are solved
    def update(epic)
      # epic.assign_attributes(params.merge(updated_by: current_user))
      epic.assign_attributes(params)
      epic.save

      epic
    end
  end
end
