# frozen_string_literal: true

module JiraImport
  class UsersImporter
    MAX_USERS = 50

    def initialize(user, project, start_at)
      @project = project
      @start_at = start_at
      @user = user
    end

    def execute
      Gitlab::JiraImport.validate_project_settings!(project, user: user)

      return ServiceResponse.success(payload: nil) if jira_users.blank?

      result = UsersMapper.new(user, project, jira_users).execute
      ServiceResponse.success(payload: result)
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, URI::InvalidURIError, JIRA::HTTPError, OpenSSL::SSL::SSLError => error
      Gitlab::ErrorTracking.track_exception(error, project_id: project.id, request: url)
      ServiceResponse.error(message: "There was an error when communicating to Jira: #{error.message}")
    rescue Projects::ImportService::Error => error
      ServiceResponse.error(message: error.message)
    end

    private

    attr_reader :user, :project, :start_at, :result

    def jira_users
      @jira_users ||= client.get(url)
    end

    def url
      "/rest/api/2/users?maxResults=#{MAX_USERS}&startAt=#{start_at.to_i}"
    end

    def client
      @client ||= project.jira_service.client
    end
  end
end
