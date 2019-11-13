# frozen_string_literal: true

# This file should only be used by sub-classes, not directly by any clients of the sub-classes
# please require all dependencies below:
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/module/delegation'

module Gitlab
  module Redis
    class Wrapper
      DEFAULT_REDIS_URL = 'redis://localhost:6379'
      REDIS_CONFIG_ENV_VAR_NAME = 'GITLAB_REDIS_CONFIG_FILE'
      CONN_POOL_SIZE_FACTOR = 1.5
      # See https://github.com/redis/redis-rb/blob/master/lib/redis.rb
      REDIS_ALLOWED_CONFIG_KEYS = Set[:url, :host, :port, :path, :timeout, :connect_timeout, :password, :db, :driver,
        :id, :tcp_keepalive, :reconnect_attempts, :inherit_socket, :sentinels, :role, :cluster, :replica, :connector]

      class RedisConnectionPool
        def initialize(pool_size, redis_params)
          @conn_pool = ConnectionPool.new(size: pool_size) { ::Redis.new(redis_params) }
        end

        def with_redis
          @conn_pool.with { |redis| yield redis }
        end
      end

      class PoolConfig
        def user_specified_pool_size(params)
          config_key = self.class.name.demodulize.gsub(/Config/, '').downcase.to_sym
          params[:connection_pool_size]&.fetch(config_key, nil)
        end
      end

      class SidekiqConfig < PoolConfig
        def default_pool_size
          Sidekiq.options[:concurrency]
        end
      end

      class PumaConfig < PoolConfig
        def default_pool_size
          Puma.cli_config.options[:max_threads]
        end
      end

      class UnicornConfig < PoolConfig
        def default_pool_size
          1
        end
      end

      class << self
        delegate :params, :url, to: :new

        def with(recreate_pool: false)
          if recreate_pool || @pool.nil?
            valid_redis_params = params.select { |k, v| REDIS_ALLOWED_CONFIG_KEYS.include?(k) }
            @pool = RedisConnectionPool.new(pool_size, valid_redis_params)
          end

          @pool.with_redis { |redis| yield redis }
        end

        def pool_size
          pool_config.user_specified_pool_size(params) ||
            (CONN_POOL_SIZE_FACTOR * pool_config.default_pool_size).round
        end

        def _raw_config
          return @_raw_config if defined?(@_raw_config)

          @_raw_config =
            begin
              if filename = config_file_name
                ERB.new(File.read(filename)).result.freeze
              else
                false
              end
            rescue Errno::ENOENT
              false
            end
        end

        def default_url
          DEFAULT_REDIS_URL
        end

        # Return the absolute path to a Rails configuration file
        #
        # We use this instead of `Rails.root` because for certain tasks
        # utilizing these classes, `Rails` might not be available.
        def config_file_path(filename)
          File.expand_path("../../../config/#{filename}", __dir__)
        end

        def config_file_name
          # if ENV set for wrapper class, use it even if it points to a file does not exist
          file_name = ENV[REDIS_CONFIG_ENV_VAR_NAME]
          return file_name unless file_name.nil?

          # otherwise, if config files exists for wrapper class, use it
          file_name = config_file_path('resque.yml')
          return file_name if File.file?(file_name)

          # nil will force use of DEFAULT_REDIS_URL when config file is absent
          nil
        end

        private

        def sidekiq?
          Sidekiq.server?
        end

        def puma?
          defined?(::Puma)
        end

        def pool_config
          if sidekiq?
            SidekiqConfig.new
          elsif puma?
            PumaConfig.new
          else
            UnicornConfig.new
          end
        end
      end

      def initialize(rails_env = nil)
        @rails_env = rails_env || ::Rails.env
      end

      def params
        redis_store_options
      end

      def url
        raw_config_hash[:url]
      end

      def sentinels
        raw_config_hash[:sentinels]
      end

      def sentinels?
        sentinels && !sentinels.empty?
      end

      private

      def redis_store_options
        config = raw_config_hash
        redis_url = config.delete(:url)
        redis_uri = URI.parse(redis_url)

        if redis_uri.scheme == 'unix'
          # Redis::Store does not handle Unix sockets well, so let's do it for them
          config[:path] = redis_uri.path
          query = redis_uri.query
          unless query.nil?
            queries = CGI.parse(redis_uri.query)
            db_numbers = queries["db"] if queries.key?("db")
            config[:db] = db_numbers[0].to_i if db_numbers.any?
          end

          config
        else
          redis_hash = ::Redis::Store::Factory.extract_host_options_from_uri(redis_url)
          # order is important here, sentinels must be after the connection keys.
          # {url: ..., port: ..., sentinels: [...]}
          redis_hash.merge(config)
        end
      end

      def raw_config_hash
        config_data = fetch_config

        if config_data
          config_data.is_a?(String) ? { url: config_data } : config_data.deep_symbolize_keys
        else
          { url: self.class.default_url }
        end
      end

      def fetch_config
        return false unless self.class._raw_config

        yaml = YAML.load(self.class._raw_config)

        # If the file has content but it's invalid YAML, `load` returns false
        if yaml
          yaml.fetch(@rails_env, false)
        else
          false
        end
      end
    end
  end
end
