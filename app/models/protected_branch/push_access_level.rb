# frozen_string_literal: true

class ProtectedBranch::PushAccessLevel < ApplicationRecord
  include ProtectedBranchAccess

  belongs_to :deploy_key

  validates :deploy_key,
            absence: true,
            unless: :protected_refs_for_users_required_and_available

  validates :access_level, uniqueness: { if: :role?,
            conditions: -> { where(user_id: nil, group_id: nil, deploy_key_id: nil) } }

  validates :deploy_key_id, uniqueness: { allow_nil: true }
  validate :validate_deploy_key_membership, if: :protected_refs_for_users_required_and_available

  def role?
    type == :role
  end

  def protected_refs_for_users_required_and_available
    type != :role && project.feature_available?(:protected_refs_for_users)
  end

  def validate_deploy_key_membership
    return unless deploy_key

    unless project.deploy_keys_projects.where(deploy_key_id: deploy_key.id).exists?
      self.errors.add(:deploy_key, 'is not enabled for this project')
    end
  end

  def type
    if self.user.present?
      :user
    elsif self.group.present?
      :group
    elsif self.deploy_key.present?
      :deploy_key
    else
      :role
    end
  end
end
