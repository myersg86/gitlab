# frozen_string_literal: true

module Resolvers
  class IssueResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    description 'Retrieve a single issue'

    type Types::IssueType, null: true

    authorize :admin_issue

    argument :id, GraphQL::ID_TYPE,
             required: true,
             description: 'ID of the Issue'

    def resolve(id: nil)
      authorized_find!(id: id)
    end

    def find_object(id:)
      GitlabSchema.object_from_id(id, expected_type: ::Issue)
    end
  end
end
