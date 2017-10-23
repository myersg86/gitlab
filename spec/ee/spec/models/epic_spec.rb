require 'spec_helper'

describe Epic do
  subject { create(:epic) }

  describe 'associations' do
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(InternalId) }
  end

  describe '#to_reference' do
    let(:project) { create(:project) }
    let(:group) { create(:group, name: 'Sample group') }
    let(:epic) { create(:epic, iid: 1, group: group) }

    context 'when no arguments passed' do
      it 'returns the prefixed epic id' do
        expect(epic.to_reference).to eq('&1')
      end
    end

    context 'when same group is an argument' do
      it 'returns the prefixed epic id' do
        expect(epic.to_reference(group)).to eq('&1')
      end
    end

    context 'when another group is an argument' do
      it 'returns the prefixed epic id' do
        expect(epic.to_reference(create(:group))).to eq('@sample_group&1')
      end
    end

    context 'when another project is an argument' do
      it 'returns the prefixed epic id' do
        expect(epic.to_reference(create(:project))).to eq('@sample_group&1')
      end
    end

    context 'when full is true' do
      it 'returns the path to the epic including the group' do
        expect(epic.to_reference(full: true)).to          eq '@sample_group&1'
        expect(epic.to_reference(project, full: true)).to eq '@sample_group&1'
        expect(epic.to_reference(group, full: true)).to   eq '@sample_group&1'
      end
    end
  end
end
