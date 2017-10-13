class Epic < ActiveRecord::Base
  include InternalId

  # TODO: including Issuable migt be a bit tricky because of functionality we don't need
  # but we should find a way to avoid copying code

  belongs_to :author, class_name: "User"
  belongs_to :group

  validates :group, presence: true
  validates :author, presence: true
  validates :title, presence: true, length: { maximum: 255 }

  # same as issues, consider extracting to a concern
  state_machine :state, initial: :opened do
    event :close do
      transition [:opened] => :closed
    end

    state :opened
    state :closed
  end

  def project
    nil
  end
end
