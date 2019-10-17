# frozen_string_literal: true

module Geo
  module Verification
    module Primary
      class ShardWorker < Geo::Scheduler::Primary::SchedulerWorker
        sidekiq_options retry: false

        attr_accessor :shard_name

        def perform(shard_name)
          @shard_name = shard_name

          return unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)

          super()
        end

        # We need a custom key here since we are running one worker per shard
        def lease_key
          @lease_key ||= "#{self.class.name.underscore}:shard:#{shard_name}"
        end

        private

        def skip_cache_key
          "#{self.class.name.underscore}:shard:#{shard_name}:skip"
        end

        def worker_metadata
          { shard: shard_name }
        end

        def max_capacity
          current_node.verification_max_capacity
        end

        def schedule_job(resource_type, id)
          job_id = Geo::Verification::Primary::SingleWorker.perform_async(resource_type, id)

          { id: id, resource_type: resource_type, job_id: job_id } if job_id
        end

        def finder
          @finder ||= Geo::VerificationFinder.new(shard_name: shard_name)
        end

        def load_pending_resources
          # resources = find_never_verified_project_ids(batch_size: db_retrieve_batch_size)
          # remaining_capacity = db_retrieve_batch_size - resources.size
          # return resources if remaining_capacity.zero?

          # resources += find_recently_updated_project_ids(batch_size: remaining_capacity)
          # remaining_capacity = db_retrieve_batch_size - resources.size
          # return resources if remaining_capacity.zero?

          # resources + find_project_ids_to_reverify(batch_size: remaining_capacity)
        end
      end
    end
  end
end
