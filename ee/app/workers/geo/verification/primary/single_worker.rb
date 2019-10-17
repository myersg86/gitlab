# frozen_string_literal: true

module Geo
  module Verification
    module Primary
      class SingleWorker
        include ApplicationWorker
        include GeoQueue
        include ExclusiveLeaseGuard

        sidekiq_options retry: false

        LEASE_TIMEOUT = 1.hour.to_i

        attr_reader :project, :resource_type, :resource_id

        def perform(resource_type, resource_id)
          return unless Gitlab::Geo.primary?

          @resource_type, @id = resource_type, id

          try_obtain_lease do
            case resource_type
            when :project # This includes repository and wiki, it will be split later on
              verify_repository
            end
          end
        end

        private

        def verify_repository
          return unless project

          Geo::RepositoryVerificationPrimaryService.new(project).execute
        end

        def project
          @project = Project.find_by(id: resource_id)
          return if project.nil? || project.pending_delete?
        end

        def lease_key
          "geo:single_repository_verification_worker:#{resource_type}:#{resource_id}"
        end

        def lease_timeout
          LEASE_TIMEOUT
        end
      end
    end
  end
end
