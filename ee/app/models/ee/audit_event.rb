# frozen_string_literal: true

module EE
  module AuditEvent
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    TEXT_LIMIT = {
      entity_path: 5_500,
      target_details: 5_500
    }.freeze

    prepended do
      scope :by_entity, -> (entity_type, entity_id) { by_entity_type(entity_type).by_entity_id(entity_id) }

      before_validation :truncate_fields
    end

    def entity
      lazy_entity
    end

    def entity_path
      super || details[:entity_path]
    end

    def present
      AuditEventPresenter.new(self)
    end

    def target_details
      super || details[:target_details]
    end

    def lazy_entity
      BatchLoader.for(entity_id)
        .batch(
          key: entity_type, default_value: ::Gitlab::Audit::NullEntity.new
        ) do |ids, loader, args|
          model = Object.const_get(args[:key], false)
          model.where(id: ids).find_each { |record| loader.call(record.id, record) }
        end
    end

    private

    def truncate_fields
      self.entity_path = self.details[:entity_path] = entity_path&.truncate(TEXT_LIMIT[:entity_path])
      self.target_details = self.details[:target_details] = target_details&.truncate(TEXT_LIMIT[:target_details])
    end
  end
end
