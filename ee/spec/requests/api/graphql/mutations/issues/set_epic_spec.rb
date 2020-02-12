# frozen_string_literal: true

require 'spec_helper'

describe 'Setting epic of an issue' do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:issue) { create(:issue, project: project) }
  let(:epic) { create(:epic, group: group) }
  let(:input) { { epic_id: epic.id } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: issue.iid.to_s
    }
    graphql_mutation(:issue_set_epic, variables.merge(input),
                     <<-QL.strip_heredoc
                       clientMutationId
                       errors
                       issue {
                         iid
                         epic {
                           id
                         }
                       }
                       epicIssue {
                         epicIssueId
                       }
                     QL
    )
  end

  def mutation_response
    graphql_mutation_response(:issue_set_epic)
  end

  before do
    project.add_developer(current_user)
    group.add_developer(current_user)
    stub_licensed_features(epics: true)
  end

  it 'returns an error if the user is not allowed to update the issue' do
    error = "The resource that you are attempting to access does not exist or you "\
            "don't have permission to perform this action"

    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).to include(a_hash_including('message' => error))
  end

  it 'returns a successful response' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(graphql_mutation_response(:issue_set_epic)['errors']).to be_empty
    expect(mutation_response['issue']['epic']['id']).to eq(epic.id)
    expect(mutation_response['epicIssue']['epicIssueId']).to eq(EpicIssue.last.id)
  end
end
