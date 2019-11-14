# frozen_string_literal: true

require_relative 'connection_pool_config'

module Gitlab
  module Redis
    class RedisConnectionPool
      # Config keys that are not understood by the redis-client gem and should be
      # removed before passing configuration along
      CONN_POOL_CONFIG_KEYS = Set[:connection_pool_size].freeze
      # Grant an extra 50% head room when pooling conncections, to reduce the
      # chance of contention when claiming connections from various threads
      CONN_POOL_SIZE_FACTOR = 1.5

      def initialize(options = {})
        @pool_options = options[:connection_pool_size] || {}
        @redis_options = options.reject { |k, v| CONN_POOL_CONFIG_KEYS.include?(k) }
        @config = RedisConnectionPool.new_pool_config(@pool_options)
        @conn_pool = ConnectionPool.new(size: size) { ::Redis.new(@redis_options) }
      end

      # TODO: this should move out of here as part of
      # https://gitlab.com/gitlab-org/gitlab/issues/35170
      def self.new_pool_config(options)
        if Sidekiq.server?
          Gitlab::Redis::SidekiqConfig.new(options)
        elsif defined?(::Unicorn)
          Gitlab::Redis::UnicornConfig.new(options)
        elsif defined?(::Puma)
          Gitlab::Redis::PumaConfig.new(options)
        else
          Gitlab::Redis::DefaultConfig.new(options)
        end
      end

      def options
        @pool_options.dup
      end

      def redis_options
        @redis_options.dup
      end

      def size
        @config.user_specified_pool_size ||
          (CONN_POOL_SIZE_FACTOR * @config.default_pool_size).round
      end

      def with_redis
        @conn_pool.with { |redis| yield redis }
      end
    end
  end
end
