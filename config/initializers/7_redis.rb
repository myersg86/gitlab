# Make sure we initialize a Redis connection pool before multi-threaded
# execution starts by
# 1. Sidekiq
# 2. Rails.cache
# 3. HTTP clients
Gitlab::Redis::Cache.ensure_initialized!
Gitlab::Redis::Queues.ensure_initialized!
Gitlab::Redis::SharedState.ensure_initialized!
