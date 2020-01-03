# frozen_string_literal: true

# Copies system dashboard definition in .yml file into designated
# .yml file inside `.gitlab/dashboards`
module EE
  module Metrics
    module Dashboard
      module CloneDashboardService
        extend ::Gitlab::Utils::Override

        DASHBOARD_TEMPLATES = {
          ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH => ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH,
          ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH => ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH
        }.freeze

        private

        override :dashboard_template
        def dashboard_template
          DASHBOARD_TEMPLATES[params[:dashboard]]
        end
      end
    end
  end
end
