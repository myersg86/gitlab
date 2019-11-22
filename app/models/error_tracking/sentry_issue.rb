# frozen_string_literal: true

module ErrorTracking
  class SentryIssue < ApplicationRecord
    belongs_to :issue, optional: false
    belongs_to :project, optional: false

    # sentry_issue_identifier length typically appears to be 10 at the moment, not validating in case that changes
    validates :sentry_issue_identifier, presence: true
    validates :sentry_event_identifier,
      format: {
        with: /\A[a-z0-9]+\z/,
        message: 'alphanumeric characters only'
      },
      # sentry_event_identifier is generated via uuid.uuid4.hex(python)
      # so it shouldn't need to change length
      length: { is: 32 },
      presence: true
  end
end
