# frozen_string_literal: true

module Mutations
  module Issues
    class SetEpic < ::Mutations::Issues::Base
      graphql_name 'IssueSetEpic'

      argument :epic_id, GraphQL::ID_TYPE,
               required: true,
               description: 'The desired epic to assign to the issue'

      field :epic_issue, Types::EpicIssueType,
            null: true,
            description: 'The created epic issue relation'

      # rubocop: disable CodeReuse/ActiveRecord
      def resolve(project_path:, iid:, epic_id:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        epic = find_epic(current_user, issue, epic_id)
        create_params = { target_issuable: issue }
        result = create_epic_issue(epic, current_user, create_params)

        epic_issue, errors = if result[:status] == :success
                               [EpicIssue.find_by(epic: epic, issue: issue), []]
                             elsif result[:status] == :error
                               [nil, [result[:message]]]
                             else
                               [nil, []]
                             end

        {
          issue: issue,
          epic_issue: epic_issue,
          errors: errors
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def find_epic(current_user, issue, epic_id)
        return unless epic_id.present?

        group = issue.project.group
        return unless group.present?

        EpicsFinder.new(current_user, group_id: group.id,
                        include_ancestor_groups: true).find(epic_id)
      end

      def can_update_epic?(user, epic)
        user.can?(:admin_epic, epic)
      end

      def create_epic_issue(epic, current_user, create_params)
        return {} unless epic.present? && can_update_epic?(current_user, epic)

        ::EpicIssues::CreateService.new(epic, current_user, create_params).execute
      end
    end
  end
end
