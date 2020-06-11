# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::State do
  subject { create(:terraform_state) }

  it { is_expected.to be_a Terraform::FileStore }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:locked_by_user).class_name('User') }

  it { is_expected.to validate_presence_of(:project_id) }

  include_examples 'terraform state storage', :terraform_state
end
