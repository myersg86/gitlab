# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraImport::UsersMapper do
  let_it_be(:user_1) { create(:user, username: 'randomuser', name: 'USER-name1', email: 'uji@example.com') }
  let_it_be(:user_2) { create(:user, username: 'username2') }
  let_it_be(:user_5) { create(:user, username: 'username5') }
  let_it_be(:user_4) { create(:user, email: 'user4@example.com') }
  let_it_be(:user_6) { create(:user, email: 'user6@example.com') }
  let_it_be(:user_7) { create(:user, username: 'username7') }
  let_it_be(:user_8) do
    create(:user).tap { |user| create(:email, user: user, email: 'user8_email@example.com') }
  end

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group)        { create(:group) }
  let_it_be(:project)      { create(:project, group: group) }

  subject { described_class.new(current_user, project, jira_users).execute }

  describe '#execute' do
    before do
      project.add_developer(current_user)
      project.add_developer(user_1)
      project.add_developer(user_2)
      group.add_developer(user_4)
      group.add_guest(user_8)
    end

    context 'jira_users is nil' do
      let(:jira_users) { nil }

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when jira_users array is present' do
      let(:jira_users) do
        [
          { 'accountId' => 'abcd', 'displayName' => 'User-Name1' }, # matched by name
          { 'accountId' => 'efg', 'displayName' => 'username2' }, # matcher by username
          { 'accountId' => 'hij' }, # no match
          { 'accountId' => '123', 'displayName' => 'user4', 'emailAddress' => 'user4@example.com' }, # matched by email
          { 'accountId' => '456', 'displayName' => 'username5foo', 'emailAddress' => 'user5@example.com' }, # no match
          { 'accountId' => '789', 'displayName' => 'user6', 'emailAddress' => 'user6@example.com' }, # matched by email, no project member
          { 'accountId' => 'xyz', 'displayName' => 'username7', 'emailAddress' => 'user7@example.com' }, # matched by username, no project member
          { 'accountId' => 'vhk', 'displayName' => 'user8', 'emailAddress' => 'user8_email@example.com' }, # matched by secondary email
          { 'accountId' => 'uji', 'displayName' => 'user9', 'emailAddress' => 'uji@example.com' } # matched by email, same as user_1
        ]
      end

      let(:mapped_users) do
        [
          { jira_account_id: 'abcd', jira_display_name: 'User-Name1', jira_email: nil, gitlab_id: user_1.id },
          { jira_account_id: 'efg', jira_display_name: 'username2', jira_email: nil, gitlab_id: user_2.id },
          { jira_account_id: 'hij', jira_display_name: nil, jira_email: nil, gitlab_id: nil },
          { jira_account_id: '123', jira_display_name: 'user4', jira_email: 'user4@example.com', gitlab_id: user_4.id },
          { jira_account_id: '456', jira_display_name: 'username5foo', jira_email: 'user5@example.com', gitlab_id: nil },
          { jira_account_id: '789', jira_display_name: 'user6', jira_email: 'user6@example.com', gitlab_id: nil },
          { jira_account_id: 'xyz', jira_display_name: 'username7', jira_email: 'user7@example.com', gitlab_id: nil },
          { jira_account_id: 'vhk', jira_display_name: 'user8', jira_email: 'user8_email@example.com', gitlab_id: user_8.id },
          { jira_account_id: 'uji', jira_display_name: 'user9', jira_email: 'uji@example.com', gitlab_id: user_1.id }
        ]
      end

      it 'returns users mapped to Gitlab' do
        expect(subject).to eq(mapped_users)
      end

      # 1 query for getting matched users, 3 queries for MembersFinder
      it 'runs only 4 queries' do
        expect { subject }.not_to exceed_query_limit(4)
      end
    end
  end
end
