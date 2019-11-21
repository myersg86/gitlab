# frozen_string_literal: true

module NpmHelper
  def generate_npmrc_template_content
    gitlab_url = ::Gitlab.config.gitlab.url
    package_url = ::Gitlab::Utils.append_path(gitlab_url, expose_path(api_v4_packages_npm_package_name_path))
    projects_url = ::Gitlab::Utils.append_path(gitlab_url, expose_path(api_v4_projects_path))
    registry_url = package_url.sub("package_name", "")

    npmrc_template(registry_url, projects_url)
  end

  def npmrc_template(registry_url, project_url)
    %Q(
# Add this line for each package scope you want to use GitLab as a registry for, changing <package-scope> to suit your package
@<package-scope>:registry=#{registry_url}

# Uncomment the below line if you wish to upload NPM packages to the package registry
# Replace <your_project_id> with the project id of your registry and <your_auth_token> with your auth token
# #{project_url}/<your_project_id>/packages/npm/:_authToken=<your_auth_token>

# Replace <your-auth-token> with a user or ci auth token
#{registry_url}:_authToken=<your-auth-token>
)
  end
end
