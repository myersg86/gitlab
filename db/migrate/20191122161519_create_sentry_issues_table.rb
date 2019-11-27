# frozen_string_literal: true

class CreateSentryIssuesTable < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :sentry_issues do |t|
      t.references :issue,
        foreign_key: { on_delete: :cascade },
        index: { unique: true },
        null: false
      t.bigint :sentry_issue_identifier, null: false
      # this is the id of the latest sentry event at the time of gitlab issue creation
      t.string :sentry_event_identifier, limit: 255, null: false
    end
  end
end
