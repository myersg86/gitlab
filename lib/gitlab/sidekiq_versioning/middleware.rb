# frozen_string_literal: true

module Gitlab
  module SidekiqVersioning
    class Middleware
      def call(worker, job, queue)
        worker.job_version = job['version'] if worker.is_a?(ApplicationWorker) && Feature.enabled?(:sidekiq_versioning, default_enabled: true)

        yield
      end
    end
  end
end
