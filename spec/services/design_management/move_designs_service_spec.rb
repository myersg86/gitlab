# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::MoveDesignsService do
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:developer) { create(:user, developer_projects: [issue.project]) }
  let_it_be(:designs) { create_list(:design, 3, issue: issue) }

  let(:project) { issue.project }

  let(:service) { described_class.new(current_user, params) }

  let(:params) do
    {
      current_design: current_design,
      previous_design: previous_design,
      next_design: next_design
    }
  end

  let(:current_user) { developer }
  let(:current_design) { nil }
  let(:previous_design) { nil }
  let(:next_design) { nil }

  before do
    # TODO: remove when this ability is implemented
    allow(developer).to receive(:can?).with(:move_design, current_design).and_return(true)
  end

  describe '#execute' do
    subject { service.execute }

    context 'the feature is unavailable' do
      before do
        stub_feature_flags(reorder_designs: false)
      end

      it 'raises CannotMove' do
        expect(subject).to be_error.and(have_attributes(message: :CannotMove))
      end
    end

    context 'the user cannot move designs' do
      let(:current_design) { designs.first }
      let(:current_user) { build_stubbed(:user) }

      it 'raises CannotMove' do
        expect(subject).to be_error.and(have_attributes(message: :CannotMove))
      end
    end

    context 'the designs are not distinct' do
      let(:current_design) { designs.first }
      let(:previous_design) { designs.first }

      it 'raises NotDistinct' do
        expect(subject).to be_error.and(have_attributes(message: :NotDistinct))
      end
    end

    context 'the designs are not on the same issue' do
      let(:current_design) { designs.first }
      let(:previous_design) { create(:design) }

      it 'raises NotDistinct' do
        expect(subject).to be_error.and(have_attributes(message: :NotSameIssue))
      end
    end

    context 'no focus is passed' do
      let(:previous_design) { designs.second }
      let(:next_design) { designs.third }

      it 'raises NoFocus' do
        expect(subject).to be_error.and(have_attributes(message: :NoFocus))
      end
    end

    context 'no neighbours are passed' do
      let(:current_design) { designs.first }

      it 'raises NoNeighbors' do
        expect(subject).to be_error.and(have_attributes(message: :NoNeighbors))
      end
    end

    context 'the designs are not adjacent' do
      let(:current_design) { designs.first }
      let(:previous_design) { designs.second }
      let(:next_design) { designs.third }

      it 'raises NotAdjacent' do
        # TODO: remove when the `relative_position` column has been implemented
        allow(previous_design).to receive(:immediately_before?)
          .with(next_design).and_return(false)

        expect(subject).to be_error.and(have_attributes(message: :NotAdjacent))
      end
    end

    context 'moving a design with neighbours' do
      let(:current_design) { designs.first }
      let(:previous_design) { designs.second }
      let(:next_design) { designs.third }

      it 'calls move_between and is successful' do
        # TODO: remove when the `relative_position` column has been implemented
        allow(previous_design).to receive(:immediately_before?)
          .with(next_design).and_return(true)

        allow(current_design).to receive(:move_between).with(previous_design, next_design)

        expect(subject).to be_success
      end
    end
  end
end
