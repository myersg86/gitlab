# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200723040950_migrate_incident_issues_to_incident_type.rb')

RSpec.describe MigrateIncidentIssuesToIncidentType do
  let(:migration) { described_class.new }
  let(:label_props) { IncidentManagement::CreateIncidentLabelService::LABEL_PROPERTIES }
  let(:label) { create(:label, label_props) }
  let!(:incident_issue) { create(:issue, labels: [label], author: User.alert_bot)}
  let!(:other_issue) { create(:issue) }

  describe '#up' do
    it 'updates the incident issue type' do
      expect { migrate! }
        .to change { incident_issue.reload.issue_type }
        .from('issue')
        .to('incident')

      expect(other_issue.reload.issue_type).to eql('issue')
    end
  end

  describe '#down' do
    let!(:incident_issue) { create(:incident, labels: [label], author: User.alert_bot)}

    it 'updates the incident issue type' do
      migration.up

      expect { migration.down }
        .to change { incident_issue.reload.issue_type }
        .from('incident')
        .to('issue')

      expect(other_issue.reload.issue_type).to eql('issue')
    end
  end
end
