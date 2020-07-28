# frozen_string_literal: true

class MigrateIncidentIssuesToIncidentType < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  INCIDENT_ISSUE_TYPE = 1
  ISSUE_ISSUE_TYPE = 0
  BATCH_SIZE = 1000

  LABEL_PROPERTIES = {
    title: 'incident',
    color: '#CC0033',
    description: <<~DESCRIPTION.chomp
      Denotes a disruption to IT services and \
      the associated issues require immediate attention
    DESCRIPTION
  }.freeze

  class Issue < ActiveRecord::Base
    include EachBatch

    scope :incident_labelled, -> do
      joins("INNER JOIN label_links ON label_links.target_type = 'Issue' AND label_links.target_id = issues.id")
        .joins("INNER JOIN labels ON labels.id = label_links.label_id")
        .where(labels: { title: LABEL_PROPERTIES[:title], color: LABEL_PROPERTIES[:color], description: LABEL_PROPERTIES[:description] })
    end

    scope :incident_issues, -> { where(issue_type: INCIDENT_ISSUE_TYPE) }
  end

  def up
    incident_issues = Issue.incident_labelled

    incident_issues.each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(issue_type: INCIDENT_ISSUE_TYPE )
    end
  end

  def down
    incident_issues = Issue.incident_issues

    incident_issues.each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(issue_type: ISSUE_ISSUE_TYPE )
    end
  end
end
