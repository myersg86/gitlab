# frozen_string_literal: true

module Geo
  module Verification
    module Secondary
      class SingleWorker
        include ApplicationWorker
        include GeoQueue
        include ExclusiveLeaseGuard
        include Gitlab::Geo::ProjectLogHelpers

        sidekiq_options retry: false

        LEASE_TIMEOUT = 1.hour.to_i

        attr_reader :project_registry, :resource_type, :resource_id
        private     :project_registry, :resource_type, :resource_id

        delegate :project, to: :project_registry

        def perform(resource_type, resource_id)
          return unless Gitlab::Geo.secondary?

          @resource_type, @resource_id = resource_type, resource_id

          try_obtain_lease do
            case resource_type
            when :project # This includes repository and wiki, it will be split later on
              verify_checksum(:repository)
              verify_checksum(:wiki)
            end
          end
        end

        private

        def verify_checksum(type)
          return unless project_registry

          Geo::RepositoryVerificationSecondaryService.new(project_registry, type).execute
        rescue => e
          log_error('Error verifying the repository checksum', e, type: type)
          raise e
        end

        def project_registry
          @project_registry = Geo::ProjectRegistry.find_by(id: resource_id)
          return if project_registry.nil? || project.nil? || project.pending_delete?
        end

        def lease_key
          "geo:repository_verification:secondary:single_worker:#{resource_type}:#{resource_id}"
        end

        def lease_timeout
          LEASE_TIMEOUT
        end
      end
    end
  end
end
