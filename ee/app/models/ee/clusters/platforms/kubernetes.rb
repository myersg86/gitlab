# frozen_string_literal: true

module EE
  module Clusters
    module Platforms
      module Kubernetes
        extend ActiveSupport::Concern
        include ::Gitlab::Utils::StrongMemoize

        CACHE_KEY_GET_POD_LOG = 'get_pod_log'

        LOGS_LIMIT = 500.freeze

        def calculate_reactive_cache_for(environment)
          result = super
          result[:deployments] = read_deployments(environment.deployment_namespace) if result

          result
        end

        def rollout_status(environment, data)
          project = environment.project

          deployments = filter_by_project_environment(data[:deployments], project.full_path_slug, environment.slug)
          pods = filter_by_project_environment(data[:pods], project.full_path_slug, environment.slug) if data[:pods]&.any?

          legacy_deployments = filter_by_legacy_label(data[:deployments], project.full_path_slug, environment.slug)

          ::Gitlab::Kubernetes::RolloutStatus.from_deployments(*deployments, pods: pods, legacy_deployments: legacy_deployments)
        end

        def read_pod_logs(environment_id, pod_names, namespace, container: nil)
          # environment_id is required for use in reactive_cache_updated(),
          # to invalidate the ETag cache.

          without_reactive_cache(
            CACHE_KEY_GET_POD_LOG,
            'environment_id' => environment_id,
            'pod_names' => pod_names,
            'namespace' => namespace,
            'container' => container
          ) do |result|
            result
          end
        end

        def calculate_reactive_cache(request, opts)
          case request
          when CACHE_KEY_GET_POD_LOG
            container = opts['container']
            pod_names = opts['pod_names']
            namespace = opts['namespace']

            handle_exceptions(_('Pod not found'), pod_names: pod_names, container_name: container) do
              container ||= container_names_of(pod_names, namespace).first

              pod_logs(pod_names, namespace, container: container)
            end
          end
        end

        def reactive_cache_updated(request, opts)
          super

          case request
          when CACHE_KEY_GET_POD_LOG
            environment = ::Environment.find_by(id: opts['environment_id'])
            return unless environment

            ::Gitlab::EtagCaching::Store.new.tap do |store|
              store.touch(
                ::Gitlab::Routing.url_helpers.k8s_pod_logs_project_environment_path(
                  environment.project,
                  environment,
                  opts['pod_names'],
                  opts['container_name'],
                  format: :json
                )
              )
            end
          end
        end

        private

        def pod_logs(pod_names, namespace, container: nil)
          logs = if ::Feature.enabled?(:enable_cluster_application_elastic_stack) && elastic_stack_client
                   elastic_stack_pod_logs(namespace, pod_names, container)
                 else
                   platform_pod_logs(namespace, pod_names, container)
                 end

          {
            logs: logs,
            status: :success,
            pod_names: pod_names,
            container_name: container
          }
        end

        def platform_pod_logs(namespace, pod_name, container_name)
          logs = kubeclient.get_pod_log(
            pod_name, namespace, container: container_name, tail_lines: LOGS_LIMIT
          ).body

          logs.strip.split("\n")
        end

        def elastic_stack_pod_logs(namespace, pod_name, container_name)
          client = elastic_stack_client
          return [] if client.nil?

          ::Gitlab::Elasticsearch::Logs.new(client).pod_logs(namespace, pod_name, container_name)
        end

        def elastic_stack_client
          strong_memoize(:elastic_stack_client) do
            cluster.application_elastic_stack&.elasticsearch_client
          end
        end

        def handle_exceptions(resource_not_found_error_message, opts, &block)
          yield
        rescue Kubeclient::ResourceNotFoundError
          {
            error: resource_not_found_error_message,
            status: :error
          }.merge(opts)
        rescue Kubeclient::HttpError => e
          ::Gitlab::Sentry.track_acceptable_exception(e)

          {
            error: _('Kubernetes API returned status code: %{error_code}') % {
              error_code: e.error_code
            },
            status: :error
          }.merge(opts)
        end

        def container_names_of(pod_names, namespace)
          return [] if pod_names.empty?

          container_names = []
          pod_names.each do |pod_name|
            pod_details = kubeclient.get_pod(pod_name, namespace)

            container_names << pod_details.spec.containers.collect(&:name)
          end

          container_names
        end

        def read_deployments(namespace)
          kubeclient.get_deployments(namespace: namespace).as_json
        rescue Kubeclient::ResourceNotFoundError
          []
        end
      end
    end
  end
end
