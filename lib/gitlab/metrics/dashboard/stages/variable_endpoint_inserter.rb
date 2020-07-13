# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class VariableEndpointInserter < BaseStage
          VARIABLE_TYPE_METRIC_LABEL_VALUES = 'metric_label_values'

          def transform!
            for_variables do |variable_name, variable|
              if variable.is_a?(Hash) && variable[:type] == VARIABLE_TYPE_METRIC_LABEL_VALUES
                variable[:options][:prometheus_endpoint_path] = endpoint_for_variable(variable.dig(:options, :series_selector))
              end
            end
          end

          private

          def endpoint_for_variable(series_selector)
            Gitlab::Routing.url_helpers.project_prometheus_api_path(
              project,
              proxy_path: ::Prometheus::ProxyService::PROMETHEUS_SERIES_API,
              match: Array(series_selector),
              env_id: params[:environment]&.id
            )
          end
        end
      end
    end
  end
end
