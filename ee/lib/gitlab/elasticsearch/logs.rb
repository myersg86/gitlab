# frozen_string_literal: true

module Gitlab
  module Elasticsearch
    class Logs
      # How many log lines to fetch in a query
      LOGS_LIMIT = 500

      def initialize(client)
        @client = client
      end

      def pod_logs(namespace, pod_names, container_name = nil)
        query = {
          bool: {
            must: [
              { match_phrase: { "kubernetes.namespace": namespace } },
              { bool: { should: pod_name_queries(pod_names) } }
            ]
          }
        }

        body = {
          query: query,
          # reverse order so we can query N-most recent records
          sort: [
            { "@timestamp": { order: :desc } },
            { "offset": { order: :desc } }
          ],
          # only return the message field in the response
          # _source: ["message"],
          # fixed limit for now, we should support paginated queries
          size: ::Gitlab::Elasticsearch::Logs::LOGS_LIMIT
        }

        response = @client.search body: body

        result = response.fetch("hits", {}).fetch("hits", []).map do |record|
           pod_name = record.dig("_source", "kubernetes", "pod", "name")
          
          "#{pod_name}: #{record["_source"]["message"]}"
        end

        # we queried for the N-most recent records but we want them ordered oldest to newest
        result.reverse
      end

      def pod_name_queries(pod_names)
        pod_names.map do |pod_name|
          { match_phrase: { "kubernetes.pod.name" => { query: pod_name } } }
        end
      end
    end
  end
end
