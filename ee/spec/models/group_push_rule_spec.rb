# frozen_string_literal: true

require 'spec_helper'

describe GroupPushRule do
  let(:push_rule) { create(:group_push_rule) }

  describe "Associations" do
    it { is_expected.to belong_to(:group) }
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_numericality_of(:max_file_size).is_greater_than_or_equal_to(0).only_integer }

    it 'validates RE2 regex syntax' do
      push_rule = build(:push_rule, branch_name_regex: '(ee|ce).*\1')

      expect(push_rule).not_to be_valid
      expect(push_rule.errors.full_messages.join).to match /invalid escape sequence/
    end
  end

  it 'defaults regexp_uses_re2 to true' do
    push_rule = create(:push_rule)

    expect(push_rule.regexp_uses_re2).to eq(true)
  end

  it 'updates regexp_uses_re2 to true on edit' do
    push_rule = create(:push_rule, regexp_uses_re2: nil)

    expect do
      push_rule.update!(branch_name_regex: '.*')
    end.to change(push_rule, :regexp_uses_re2).to true
  end
end
