module BasicStateMachine
  extend ActiveSupport::Concern

  included do
    state_machine :state, initial: :opened do
      event :close do
        transition [:opened] => :closed
      end

      event :reopen do
        transition closed: :opened
      end

      state :opened
      state :closed

      before_transition any => :closed do |issue|
        issue.closed_at = Time.zone.now
      end
    end
  end
end
