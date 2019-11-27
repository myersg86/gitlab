# frozen_string_literal: true

module Search
  module Elasticsearchable
    def use_elasticsearch?
      return false if params[:basic_search]
      return false unless ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: elasticsearchable_scope)
      return true unless ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?

      in_elasticsearch_index?
    end

    def in_elasticsearch_index?
      return true unless elasticsearchable_scope

      elasticsearchable_scope.in_elasticsearch_index?
    end

    def elasticsearchable_scope
      raise NotImplementedError
    end
  end
end
