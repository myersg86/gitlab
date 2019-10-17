# frozen_string_literal: true

module Geo
  module Verification
    module Primary
      class BatchWorker < Geo::Scheduler::Primary::PerShardSchedulerWorker
        def perform
          # TODO: move this check downstream
          # return unless Gitlab::Geo.repository_verification_enabled?

          super
        end

        def schedule_job(shard_name)
          Geo::Verification::Primary::ShardWorker.perform_async(shard_name)
        end
      end
    end
  end
end
