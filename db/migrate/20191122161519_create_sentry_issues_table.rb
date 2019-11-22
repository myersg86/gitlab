# frozen_string_literal: true

class CreateSentryIssuesTable < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :sentry_issues do |t|
      t.references :issue,
        foreign_key: { on_delete: :cascade },
        index: { unique: true },
        null: false
      t.references :project,
        foreign_key: { on_delete: :cascade },
        null: false
      t.integer :sentry_issue_identifier
      # this is the id of the latest sentry event at the time of gitlab issue creation
      t.string :sentry_event_identifier
    end
  end
end
