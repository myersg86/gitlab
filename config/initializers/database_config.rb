# frozen_string_literal: true

def report_pool_size(db_name, previous_pool_size, current_pool_size)
  if current_pool_size.to_i < previous_pool_size.to_i
    raise "FATAL: Database pool size has shrunk for #{db_name}: " \
        "current (#{current_pool_size}) < previous (#{previous_pool_size})"
  end

  log_message = ["#{db_name} connection pool size: #{current_pool_size.inspect}"]

  if previous_pool_size && current_pool_size > previous_pool_size
    log_message << "(increased from #{previous_pool_size} to match thread count)"
  end

  Gitlab::AppLogger.debug(log_message.join(' '))
end

def set_database_pool_size(base_class, database_config, max_threads)
  previous_pool_size = database_config['pool']

  database_config['pool'] = [database_config['pool'].to_i, max_threads].max

  connection_pool = base_class.establish_connection(database_config)

  report_pool_size(base_class.name, previous_pool_size, connection_pool.size)
end

def set_primary_database_pool_size(max_threads)
  db_config = Gitlab::Database.config ||
      Rails.application.config.database_configuration[Rails.env]
  set_database_pool_size(ActiveRecord::Base, db_config, max_threads)
end

def set_geo_database_pool_size(max_threads)
  if Gitlab::Runtime.sidekiq?
    set_database_pool_size(Geo::TrackingBase, Rails.configuration.geo_database, max_threads)
  end
end

Gitlab.ee do
  # We need to initialize the Geo database before
  # setting the Geo DB connection pool size.
  if File.exist?(Rails.root.join('config/database_geo.yml'))
    Rails.application.configure do
      config.geo_database = config_for(:database_geo)
    end
  end
end

# When running on multi-threaded runtimes like Puma or Sidekiq,
# set the number of threads per process as the minimum DB connection pool size.
# This is to avoid connectivity issues as was documented here:
# https://github.com/rails/rails/pull/23057
if Gitlab::Runtime.multi_threaded?
  max_threads = Gitlab::Runtime.max_threads
  set_primary_database_pool_size(max_threads)

  Gitlab.ee do
    set_geo_database_pool_size(max_threads) if Gitlab::Geo.geo_database_configured?
  end
end
