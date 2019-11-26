# frozen_string_literal: true

class SentryIssue < ApplicationRecord
  belongs_to :issue
  belongs_to :project

  validates :issue, uniqueness: true, presence: true
  # sentry_issue_identifier length typically appears to be 10 at the moment, not validating in case that changes
  validates :project, :sentry_issue_identifier, presence: true
  validates :sentry_event_identifier,
    format: {
      with: /\A[a-z0-9]+\z/,
      message: 'alphanumeric characters only'
    },
    presence: true
end
