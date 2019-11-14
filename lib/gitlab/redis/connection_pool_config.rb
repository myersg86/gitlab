# frozen_string_literal: true

module Gitlab
  module Redis
    class ConnectionPoolConfig
      attr_reader :user_specified_pool_size

      # `options` must be a hash with optional entries matching the kind of config
      # being instantiated, e.g. `DefaultConfig` requires `default: n`,
      # `PumaConfig` requires `puma: m` etc.
      def initialize(options)
        config_key = self.class.name.demodulize.gsub(/Config/, '').downcase.to_sym
        @user_specified_pool_size = options[config_key]
      end

      # implemented by subclasses
      def default_pool_size
        raise NotImplementedError
      end
    end

    class DefaultConfig < ConnectionPoolConfig
      def initialize(options)
        super
      end

      def default_pool_size
        1
      end
    end

    class UnicornConfig < DefaultConfig; end

    class SidekiqConfig < ConnectionPoolConfig
      def initialize(options)
        super
      end

      def default_pool_size
        Sidekiq.options[:concurrency]
      end
    end

    class PumaConfig < ConnectionPoolConfig
      def initialize(options)
        super
      end

      def default_pool_size
        Puma.cli_config.options[:max_threads]
      end
    end
  end
end
