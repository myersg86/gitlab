# frozen_string_literal: true

class GroupPushRule < ApplicationRecord
  include PushRuleLike

  belongs_to :group

  validates :group, presence: true

  def available?(feature_sym)
    group&.feature_available?(feature_sym)
  end

  def global?
    true
  end
end
