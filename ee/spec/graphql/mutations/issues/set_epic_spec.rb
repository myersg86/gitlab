# frozen_string_literal: true
require 'spec_helper'

describe Mutations::Issues::SetEpic do
  let(:group)   { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:epic)    { create(:epic, group: group) }
  let(:issue)   { create(:issue, project: project) }
  let(:user)    { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }) }

  describe '#resolve' do
    let(:mutated_issue) { subject[:issue] }
    let(:epic_issue_link) { subject[:epic_issue] }

    subject { mutation.resolve(project_path: project.full_path, iid: issue.iid, epic_id: epic.id) }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can update the issue' do
      before do
        stub_licensed_features(epics: true)
        project.add_developer(user)
      end

      context 'when the user can not update the epic' do
        it 'returns the issue with correct epic assigned' do
          expect(mutated_issue).to eq(issue)
          expect(mutated_issue.epic).to be_nil
          expect(epic_issue_link).to be_nil
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when the user can update the epic' do
        before do
          group.add_developer(user)
        end

        it 'returns the issue with correct epic assigned' do
          expect(mutated_issue).to eq(issue)
          expect(mutated_issue.epic).to eq(epic)
          expect(epic_issue_link.issue_id).to eq(issue.id)
          expect(epic_issue_link.epic_id).to eq(epic.id)
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
