# frozen_string_literal: true

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
      def self.new_pool_config(connection_pool_config)
        if Sidekiq.server?
          SidekiqConfig.new(connection_pool_config)
        elsif defined?(::Puma)
          PumaConfig.new(connection_pool_config)
        else
          UnicornConfig.new(connection_pool_config)
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

    class PoolConfig
      attr_reader :user_specified_pool_size

      def initialize(options)
        config_key = self.class.name.demodulize.gsub(/Config/, '').downcase.to_sym
        @user_specified_pool_size = options[config_key]
      end
    end

    class SidekiqConfig < PoolConfig
      def initialize(options)
        super
      end

      def default_pool_size
        Sidekiq.options[:concurrency]
      end
    end

    class PumaConfig < PoolConfig
      def initialize(options)
        super
      end

      def default_pool_size
        Puma.cli_config.options[:max_threads]
      end
    end

    class UnicornConfig < PoolConfig
      def initialize(options)
        super
      end

      def default_pool_size
        1
      end
    end
  end
end
