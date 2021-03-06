# frozen_string_literal: true

module EE
  module API
    module Entities
      module Nuget
        class PackagesVersions < Grape::Entity
          expose :versions
        end
      end
    end
  end
end
