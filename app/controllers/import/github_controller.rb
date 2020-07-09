# frozen_string_literal: true

class Import::GithubController < Import::BaseController
  extend ::Gitlab::Utils::Override

  include ImportHelper
  include ActionView::Helpers::SanitizeHelper

  before_action :verify_import_enabled
  before_action :provider_auth, only: [:status, :realtime_changes, :create]
  before_action :expire_etag_cache, only: [:status, :create]

  rescue_from Octokit::Unauthorized, with: :provider_unauthorized
  rescue_from Octokit::TooManyRequests, with: :provider_rate_limit

  def new
    if !ci_cd_only? && github_import_configured? && logged_in_with_provider?
      go_to_provider_for_permissions
    elsif session[access_token_key]
      redirect_to status_import_url
    end
  end

  def callback
    session[access_token_key] = client.get_token(params[:code])
    redirect_to status_import_url
  end

  def personal_access_token
    session[access_token_key] = params[:personal_access_token]&.strip
    redirect_to status_import_url
  end

  def status
    # Request repos to display error page if provider token is invalid
    # Improving in https://gitlab.com/gitlab-org/gitlab-foss/issues/55585
    client_repos

    super
  end

  def create
    result = Import::GithubService.new(client, current_user, import_params).execute(access_params, provider_name)

    if result[:status] == :success
      render json: serialized_imported_projects(result[:project])
    else
      render json: { errors: result[:message] }, status: result[:http_status]
    end
  end

  def realtime_changes
    super
  end

  protected

  # rubocop: disable CodeReuse/ActiveRecord
  override :importable_repos
  def importable_repos
    already_added_projects_names = already_added_projects.map(&:import_source)

    client_repos.reject { |repo| already_added_projects_names.include?(repo.full_name) }
  end
  # rubocop: enable CodeReuse/ActiveRecord

  override :incompatible_repos
  def incompatible_repos
    []
  end

  override :provider_name
  def provider_name
    :github
  end

  override :provider_url
  def provider_url
    strong_memoize(:provider_url) do
      provider = Gitlab::Auth::OAuth::Provider.config_for('github')

      provider&.dig('url').presence || 'https://github.com'
    end
  end

  private

  def import_params
    params.permit(permitted_import_params)
  end

  def permitted_import_params
    [:repo_id, :new_name, :target_namespace]
  end

  def serialized_imported_projects(projects = already_added_projects)
    ProjectSerializer.new.represent(projects, serializer: :import, provider_url: provider_url)
  end

  def expire_etag_cache
    Gitlab::EtagCaching::Store.new.tap do |store|
      store.touch(realtime_changes_path)
    end
  end

  def client
    @client ||= Gitlab::LegacyGithubImport::Client.new(session[access_token_key], client_options)
  end

  def client_repos
    @client_repos ||= filtered(client.repos)
  end

  def verify_import_enabled
    render_404 unless import_enabled?
  end

  def go_to_provider_for_permissions
    redirect_to client.authorize_url(callback_import_url)
  end

  def import_enabled?
    __send__("#{provider_name}_import_enabled?") # rubocop:disable GitlabSecurity/PublicSend
  end

  def realtime_changes_path
    public_send("realtime_changes_import_#{provider_name}_path", format: :json) # rubocop:disable GitlabSecurity/PublicSend
  end

  def new_import_url
    public_send("new_import_#{provider_name}_url", extra_import_params) # rubocop:disable GitlabSecurity/PublicSend
  end

  def status_import_url
    public_send("status_import_#{provider_name}_url", extra_import_params) # rubocop:disable GitlabSecurity/PublicSend
  end

  def callback_import_url
    public_send("users_import_#{provider_name}_callback_url", extra_import_params) # rubocop:disable GitlabSecurity/PublicSend
  end

  def provider_unauthorized
    session[access_token_key] = nil
    redirect_to new_import_url,
      alert: "Access denied to your #{Gitlab::ImportSources.title(provider_name.to_s)} account."
  end

  def provider_rate_limit(exception)
    reset_time = Time.zone.at(exception.response_headers['x-ratelimit-reset'].to_i)
    session[access_token_key] = nil
    redirect_to new_import_url,
      alert: _("GitHub API rate limit exceeded. Try again after %{reset_time}") % { reset_time: reset_time }
  end

  def access_token_key
    :"#{provider_name}_access_token"
  end

  def access_params
    { github_access_token: session[access_token_key] }
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def logged_in_with_provider?
    current_user.identities.exists?(provider: provider_name)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def provider_auth
    if !ci_cd_only? && session[access_token_key].blank?
      go_to_provider_for_permissions
    end
  end

  def ci_cd_only?
    %w[1 true].include?(params[:ci_cd_only])
  end

  def client_options
    { wait_for_rate_limit_reset: false }
  end

  def extra_import_params
    {}
  end

  def sanitized_filter_param
    @filter ||= sanitize(params[:filter])
  end

  def filter_attribute
    :name
  end
end

Import::GithubController.prepend_if_ee('EE::Import::GithubController')
