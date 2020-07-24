# frozen_string_literal: true

class ClusterSerializer < BaseSerializer
  include WithPagination
  entity ClusterEntity

  def represent_list(resource)
    represent(resource, {
      only: [
        :cluster_type,
        :connection_error,
        :enabled,
        :environment_scope,
        :gitlab_managed_apps_logs_path,
        :metrics_connection_error,
        :name,
        :node_connection_error,
        :nodes,
        :path,
        :provider_type,
        :status
      ]
    })
  end

  def represent_status(resource)
    represent(resource, { only: [:status, :status_reason, :applications] })
  end
end
