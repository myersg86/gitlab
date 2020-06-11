# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateVersion do
  subject { create(:terraform_state_version) }

  it { is_expected.to be_a Terraform::FileStore }

  it { is_expected.to belong_to(:terraform_state) }
  it { is_expected.to belong_to(:created_by_user).class_name('User') }

  include_examples 'terraform state storage', :terraform_state_version
end
