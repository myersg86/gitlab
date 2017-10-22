class Epic < ActiveRecord::Base
  include InternalId
  include Issuable
  include BasicStateMachine

  belongs_to :assignee, class_name: "User"
  belongs_to :group

  validates :group, presence: true

  # TODO: referencing between groups
  def to_reference(from = nil, full: nil)
    reference = "#{self.class.reference_prefix}#{iid}"

    # "#{group.to_reference(from, full: full)}#{reference}"
  end

  def assignees
    Array(assignee)
  end

  def project
    nil
  end

  # TODO: it supports weight but not as separated column but sum of all weights
  def supports_weight?
    false
  end

  def self.reference_prefix
    '&'
  end

  def self.reference_pattern
  end
end
