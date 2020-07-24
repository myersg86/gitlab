# frozen_string_literal: true

class MigrateIncidentIssuesToIncidentType < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  INCIDENT_ISSUE_TYPE = 1
  ISSUE_ISSUE_TYPE = 0

  # Add each_batch functionality to Issue
  Issue.send(:include, 'EachBatch'.constantize)

  def up
    incident_issues = Issue.authored(User.alert_bot)
                      .with_label_attributes(IncidentManagement::CreateIncidentLabelService::LABEL_PROPERTIES)

    incident_issues.each_batch do |batch|
      batch.update_all(issue_type: INCIDENT_ISSUE_TYPE )
    end
  end

  def down
    incident_issues = Issue.incident

    incident_issues.each_batch do |batch|
      batch.update_all(issue_type: ISSUE_ISSUE_TYPE )
    end
  end
end
