# frozen_string_literal: true

module EE
  module API
    module Entities
      module GroupDetail
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit
          expose :extra_shared_runners_minutes_limit
          expose :prevent_forking_outside_group?,
                 as: :prevent_forking_outside_group,
                 if: ->(group, options) {
                   Ability.allowed?(options[:current_user], :change_prevent_group_forking, group)
                 }
        end
      end
    end
  end
end
