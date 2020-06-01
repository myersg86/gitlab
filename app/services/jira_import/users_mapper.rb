# frozen_string_literal: true

module JiraImport
  class UsersMapper
    include Gitlab::Utils::StrongMemoize

    # The class is called from UsersImporter and small batches of users are expected
    # In case the mapping of a big batch of users is expected to be passed here
    # the implementation needs to changee here and handles the matching in batches
    def initialize(current_user, project, jira_users)
      @current_user = current_user
      @project = project
      @jira_users = jira_users
    end

    def execute
      return [] if jira_users.blank?

      jira_users.map do |jira_user|
        {
          jira_account_id: jira_user['accountId'],
          jira_display_name: jira_user['displayName'],
          jira_email: jira_user['emailAddress'],
          gitlab_id: find_gitlab_id(jira_user)
        }
      end
    end

    private

    attr_reader :current_user, :project, :jira_users

    def matched_users
      strong_memoize(:matched_users) do
        pairs_to_match = jira_users.map do |user|
          "('#{user['displayName']&.downcase}', '#{user['emailAddress']&.downcase}')"
        end.join(',')

        User.by_emails_or_names(pairs_to_match)
      end
    end

    def find_gitlab_id(jira_user)
      user = matched_users.find do |matched_user|
        matched_user['jira_email'] == jira_user['emailAddress']&.downcase ||
          matched_user['jira_name'].downcase == jira_user['displayName']&.downcase
      end

      return unless user

      user_id = user['user_id']

      return unless project_member_ids.include?(user_id)

      user_id
    end

    def project_member_ids
      # rubocop: disable CodeReuse/ActiveRecord
      @project_member_ids ||= MembersFinder.new(project, current_user).execute.pluck(:user_id)
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
