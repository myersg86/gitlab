# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GroupSearchResults do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  describe 'user search' do
    it 'returns the users belonging to the group matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      create(:group_member, :developer, user: user1, group: group)

      user2 = create(:user, username: 'michael_bluth')
      create(:group_member, :developer, user: user2, group: group)

      create(:user, username: 'gob_2018')

      result = described_class.new(user, anything, group, 'gob').objects('users')

      expect(result).to eq [user1]
    end

    it 'returns the user belonging to the subgroup matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      subgroup = create(:group, parent: group)
      create(:group_member, :developer, user: user1, group: subgroup)

      create(:user, username: 'gob_2018')

      result = described_class.new(user, anything, group, 'gob').objects('users')

      expect(result).to eq [user1]
    end

    it 'returns the user belonging to the parent group matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      parent_group = create(:group, children: [group])
      create(:group_member, :developer, user: user1, group: parent_group)

      create(:user, username: 'gob_2018')

      result = described_class.new(user, anything, group, 'gob').objects('users')

      expect(result).to eq [user1]
    end

    it 'does not return the user belonging to the private subgroup' do
      user1 = create(:user, username: 'gob_bluth')
      subgroup = create(:group, :private, parent: group)
      create(:group_member, :developer, user: user1, group: subgroup)

      create(:user, username: 'gob_2018')

      result = described_class.new(user, anything, group, 'gob').objects('users')

      expect(result).to eq []
    end

    it 'does not return the user belonging to an unrelated group' do
      user = create(:user, username: 'gob_bluth')
      unrelated_group = create(:group)
      create(:group_member, :developer, user: user, group: unrelated_group)

      result = described_class.new(user, anything, group, 'gob').objects('users')

      expect(result).to eq []
    end
  end

  describe 'issue search' do
    let(:query) { 'issue' }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }
    let(:subgroup) { create(:group, parent: group) }
    let(:project) { create(:project, :internal, namespace: subgroup) }
    let!(:issue) { create(:issue, project: project, title: 'Issue 1') }
    let!(:security_issue_1) { create(:issue, :confidential, project: project, title: 'Security issue 1', author: author) }
    let!(:security_issue_2) { create(:issue, :confidential, project: project, title: 'Security issue 2', assignees: [assignee]) }

    it 'does not list confidential issues for group members with guest role' do
      group.add_guest(member)

      results = described_class.new(member, Project.all, group, query)
      issues = results.objects('issues')

      expect(issues).to include(issue)
      expect(issues).not_to include(security_issue_1)
      expect(issues).not_to include(security_issue_2)
      expect(results.limited_issues_count).to eq(1)
    end

    it 'lists confidential issues for the author' do
      results = described_class.new(author, Project.all, group, query)
      issues = results.objects('issues')

      expect(issues).to include(issue)
      expect(issues).to include(security_issue_1)
      expect(issues).not_to include(security_issue_2)
      expect(results.limited_issues_count).to eq(2)
    end

    it 'lists confidential issues for the assignee' do
      results = described_class.new(assignee, Project.all, group, query)
      issues = results.objects('issues')

      expect(issues).to include(issue)
      expect(issues).not_to include(security_issue_1)
      expect(issues).to include(security_issue_2)
      expect(results.limited_issues_count).to eq(2)
    end

    it 'lists confidential issues for group members with developer role' do
      group.add_developer(member)

      results = described_class.new(member, Project.all, group, query)
      issues = results.objects('issues')

      expect(issues).to include(issue)
      expect(issues).to include(security_issue_1)
      expect(issues).to include(security_issue_2)
      expect(results.limited_issues_count).to eq(3)
    end

    it 'lists all project issues for an admin' do
      results = described_class.new(admin, Project.all, group, query)
      issues = results.objects('issues')

      expect(issues).to include(issue)
      expect(issues).to include(security_issue_1)
      expect(issues).to include(security_issue_2)
      expect(results.limited_issues_count).to eq(3)
    end

    it 'sets include_subgroups flag by default' do
      result = described_class.new(user, anything, group, 'gob')

      expect(result.issuable_params[:include_subgroups]).to eq(true)
    end

    it 'sets attempt_group_search_optimizations flag by default' do
      result = described_class.new(user, anything, group, 'gob')

      expect(result.issuable_params[:attempt_group_search_optimizations]).to eq(true)
    end
  end
end
