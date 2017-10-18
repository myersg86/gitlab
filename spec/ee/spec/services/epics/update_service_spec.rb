require 'spec_helper'

describe Epics::UpdateService do
  let(:group) { create(:group, :internal)}
  let(:user) { create(:user) }
  let(:epic) { create(:epic, group: group) }

  describe '#execute' do
    let(:opts) do
      {
        title: 'New title',
        description: 'New description'
      }
    end

    subject { described_class.new(nil, user, opts).execute(epic) }

    context 'a user has permissions to update the epic' do
      before do
        group.add_user(user, :developer)
      end

      it 'updates the epic correctly' do
        subject

        expect(epic).to be_valid
        expect(epic.title).to eq('New title')
        expect(epic.description).to eq('New description')
      end
    end
  end
end
