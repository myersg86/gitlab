class Epic < ActiveRecord::Base
  include InternalId
  include Issuable
  include BasicStateMachine

  belongs_to :assignee, class_name: "User"
  belongs_to :group

  validates :group, presence: true

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

  # TODO: do we need group check instead?
  def skip_project_check?
    true
  end
end
