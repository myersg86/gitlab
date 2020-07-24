# frozen_string_literal: true

class ClusterEntity < Grape::Entity
  include RequestAwareEntity

  expose :cluster_type
  expose :connection_error
  expose :enabled
  expose :environment_scope
  expose :metrics_connection_error
  expose :name
  expose :node_connection_error
  expose :nodes
  expose :provider_type
  expose :status_name, as: :status
  expose :status_reason
  expose :applications, using: ClusterApplicationEntity

  expose :path do |cluster|
    Clusters::ClusterPresenter.new(cluster).show_path # rubocop: disable CodeReuse/Presenter
  end

  expose :gitlab_managed_apps_logs_path do |cluster|
    Clusters::ClusterPresenter.new(cluster, current_user: request.current_user).gitlab_managed_apps_logs_path # rubocop: disable CodeReuse/Presenter
  end
end
