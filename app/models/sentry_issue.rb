# frozen_string_literal: true

class SentryIssue < ApplicationRecord
  belongs_to :issue

  validates :issue, uniqueness: true, presence: true
  validates :sentry_issue_identifier, presence: true
  validates :sentry_event_identifier,
    format: {
      with: /\A[a-z0-9]+\z/,
      message: 'alphanumeric characters only'
    },
    presence: true
end
