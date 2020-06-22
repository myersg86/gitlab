# frozen_string_literal: true

module Resolvers
  class IssueResolver < BaseResolver
    description 'Retrieve a single issue'

    type Types::IssueType, null: true

    argument :id, GraphQL::ID_TYPE,
             required: true,
             description: 'ID of the Issue'

    def resolve(id: nil)
      GitlabSchema.object_from_id(id, expected_type: Issue)
    end
  end
end