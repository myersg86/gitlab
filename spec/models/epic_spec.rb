require 'spec_helper'

describe Epic do
  describe 'associations' do
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:title) }
  end
end
