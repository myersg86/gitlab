# frozen_string_literal: true

module EE
  module Types
    module BoardType
      extend ActiveSupport::Concern

      prepended do
        field :weight, type: GraphQL::INT_TYPE, null: true,
              description: 'Weight of the board'

        field :epic_groups, ::Types::EpicType.connection_type, null: true,
              description: 'Epics associated with board issues',
              resolver: ::Resolvers::BoardGroupings::EpicsResolver
      end
    end
  end
end
