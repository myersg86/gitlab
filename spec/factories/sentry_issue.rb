# frozen_string_literal: true

FactoryBot.define do
  factory :sentry_issue, class: SentryIssue do
    project
    issue
    sentry_issue_identifier { 1234567891 }
    sentry_event_identifier { SecureRandom.hex(32/2) }
  end
end
