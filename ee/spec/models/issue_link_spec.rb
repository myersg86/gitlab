# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLink do
  describe '.blocked_issue_ids' do
    it 'returns only ids of issues which are blocked' do
      link1 = create(:issue_link, link_type: described_class::TYPE_BLOCKS)
      link2 = create(:issue_link, link_type: described_class::TYPE_IS_BLOCKED_BY)
      link3 = create(:issue_link, link_type: described_class::TYPE_RELATES_TO)
      link4 = create(:issue_link, source: create(:issue, :closed), link_type: described_class::TYPE_BLOCKS)

      expect(described_class.blocked_issue_ids([link1.target_id, link2.source_id, link3.source_id, link4.target_id]))
        .to match_array([link1.target_id, link2.source_id])
    end
  end

  describe '.blocking_issue_ids_for' do
    it 'returns blocking issue ids' do
      issue = create(:issue)
      blocking_issue = create(:issue, project: issue.project)
      blocked_by_issue = create(:issue, project: issue.project)
      create(:issue_link, source: blocking_issue, target: issue, link_type: IssueLink::TYPE_BLOCKS)
      create(:issue_link, source: issue, target: blocked_by_issue, link_type: IssueLink::TYPE_IS_BLOCKED_BY)

      blocking_ids = described_class.blocking_issue_ids_for(issue)

      expect(blocking_ids).to match_array([blocking_issue.id, blocked_by_issue.id])
    end
  end

  describe '.inverse_link_type' do
    it 'returns reverse type of link' do
      expect(described_class.inverse_link_type('relates_to')).to eq 'relates_to'
      expect(described_class.inverse_link_type('blocks')).to eq 'is_blocked_by'
      expect(described_class.inverse_link_type('is_blocked_by')).to eq 'blocks'
    end
  end

  describe '.blocking_issues_for_collection' do
    it 'returns blocking issues count grouped by issue id' do
      issue_1 = create(:issue)
      issue_2 = create(:issue)
      issue_3 = create(:issue)
      blocking_issue_1 = create(:issue, project: issue_1.project)
      blocking_issue_2 = create(:issue, project: issue_2.project)
      create(:issue_link, source: blocking_issue_1, target: issue_1, link_type: IssueLink::TYPE_BLOCKS)
      create(:issue_link, source: issue_2, target: blocking_issue_1, link_type: IssueLink::TYPE_IS_BLOCKED_BY)
      create(:issue_link, source: blocking_issue_2, target: issue_3, link_type: IssueLink::TYPE_BLOCKS)

      results = described_class.blocking_issues_for_collection([blocking_issue_1, blocking_issue_2])

      expect(results.find { |link| link.blocking_issue_id == blocking_issue_1.id }.count).to eq(2)
      expect(results.find { |link| link.blocking_issue_id == blocking_issue_2.id }.count).to eq(1)
    end
  end
end
