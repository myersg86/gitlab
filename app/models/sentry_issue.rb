# frozen_string_literal: true

class SentryIssue < ApplicationRecord
  belongs_to :issue

  validates :issue, uniqueness: true, presence: true
  validates :sentry_issue_identifier, presence: true

  def self.by_issue(issue)
    find_by(issue: issue)
  end
end
