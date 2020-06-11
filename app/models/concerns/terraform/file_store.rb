# frozen_string_literal: true

module Terraform
  module FileStore
    extend ActiveSupport::Concern

    DEFAULT = '{"version":1}'.freeze

    included do
      after_save :update_file_store, if: :saved_change_to_file?

      default_value_for(:file) { CarrierWaveStringFile.new(DEFAULT) }
    end

    def file_store
      super || StateUploader.default_store
    end

    def update_file_store
      # The file.object_store is set during `uploader.store!`
      # which happens after object is inserted/updated
      self.update_column(:file_store, file.object_store)
    end
  end
end
