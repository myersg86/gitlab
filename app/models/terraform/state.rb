# frozen_string_literal: true

module Terraform
  class State < ApplicationRecord
    include UsageStatistics
    include Terraform::FileStore

    HEX_REGEXP = %r{\A\h+\z}.freeze
    UUID_LENGTH = 32

    belongs_to :project
    belongs_to :locked_by_user, class_name: 'User'

    has_many :versions, class_name: 'Terraform::StateVersion', foreign_key: :terraform_state_id
    has_one :latest_version, -> { ordered_by_version_desc }, class_name: 'Terraform::StateVersion', foreign_key: :terraform_state_id

    validates :project_id, presence: true
    validates :file, absence: true, if: :versioning_enabled?
    validates :uuid, presence: true, uniqueness: true, length: { is: UUID_LENGTH },
              format: { with: HEX_REGEXP, message: 'only allows hex characters' }

    default_value_for(:uuid, allows_nil: false) { SecureRandom.hex(UUID_LENGTH / 2) }

    mount_uploader :file, StateUploader

    def latest_file
      versioning_enabled ? latest_version.file : file
    end

    def locked?
      self.lock_xid.present?
    end

    def update_file!(data, version:)
      if versioning_enabled?
        new_version = versions.find_or_initialize_by(version: version)
        new_version.created_by_user = locked_by_user
        new_version.file = data
        new_version.save!
      else
        self.file = data
        save!
      end
    end
  end
end
