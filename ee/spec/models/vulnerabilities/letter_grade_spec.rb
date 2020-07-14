# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::LetterGrade do
  let_it_be(:group) { create(:group) }
  let_it_be(:project_1) { create(:project, group: group) }
  let_it_be(:project_2) { create(:project, group: group) }
  let_it_be(:project_3) { create(:project, group: group) }
  let_it_be(:project_4) { create(:project, group: group) }
  let_it_be(:project_5) { create(:project, group: group) }

  let_it_be(:vulnerability_statistic_1) { create(:vulnerability_statistic, :a, project: project_1) }
  let_it_be(:vulnerability_statistic_2) { create(:vulnerability_statistic, :b, project: project_2) }
  let_it_be(:vulnerability_statistic_3) { create(:vulnerability_statistic, :b, project: project_3) }
  let_it_be(:vulnerability_statistic_4) { create(:vulnerability_statistic, :c, project: project_4) }
  let_it_be(:vulnerability_statistic_5) { create(:vulnerability_statistic, :f, project: project_5) }

  describe '.defaults' do
    subject(:defaults) { described_class.defaults }

    let(:expected_letter_grades) do
      {
        'a' => described_class.new(nil, 0, []),
        'b' => described_class.new(nil, 1, []),
        'c' => described_class.new(nil, 2, []),
        'd' => described_class.new(nil, 3, []),
        'f' => described_class.new(nil, 4, [])
      }
    end

    it { is_expected.to eq expected_letter_grades }
  end

  describe '.grades_for' do
    subject(:letter_grades) { described_class.grades_for(vulnerable) }

    context 'when the given vulnerable is a Group' do
      let(:vulnerable) { group }
      let(:expected_letter_grades) do
        {
          'a' => described_class.new(vulnerable, 0, [project_1.id]),
          'b' => described_class.new(vulnerable, 1, [project_2.id, project_3.id]),
          'c' => described_class.new(vulnerable, 2, [project_4.id]),
          'd' => described_class.new(vulnerable, 3, []),
          'f' => described_class.new(vulnerable, 4, [project_5.id])
        }
      end

      it 'returns the letter grades for given vulnerable' do
        expect(letter_grades).to eq(expected_letter_grades)
      end
    end

    context 'when the given vulnerable is an InstanceSecurityDashboard' do
      let(:user) { create(:user) }
      let(:vulnerable) { InstanceSecurityDashboard.new(user) }
      let(:expected_letter_grades) do
        {
          'a' => described_class.new(vulnerable, 0, [project_1.id]),
          'b' => described_class.new(vulnerable, 1, []),
          'c' => described_class.new(vulnerable, 2, []),
          'd' => described_class.new(vulnerable, 3, []),
          'f' => described_class.new(vulnerable, 4, [])
        }
      end

      before do
        project_1.add_developer(user)
        user.security_dashboard_projects << project_1
      end

      it 'returns the letter grades for given vulnerable' do
        expect(letter_grades).to eq(expected_letter_grades)
      end
    end
  end

  describe '#count' do
    let(:letter_grade) { described_class.new(group, 1, [project_3.id, project_4.id]) }
    let(:expected_projects) { [project_3, project_4] }

    subject(:count) { letter_grade.count }

    it { is_expected.to eq 2 }
  end

  describe '#letter' do
    ::Vulnerabilities::Statistic.letter_grades.each do |expected_letter, enum|
      subject(:letter) { letter_grade.letter }

      context "when providing enum value of #{enum}" do
        let(:letter_grade) { described_class.new(nil, enum) }

        it { is_expected.to eq(expected_letter) }
      end
    end
  end

  describe '#projects' do
    let(:letter_grade) { described_class.new(group, 1, [project_3.id, project_4.id]) }
    let(:expected_projects) { [project_3, project_4] }

    subject(:projects) { letter_grade.projects }

    it { is_expected.to eq(expected_projects) }
  end
end
