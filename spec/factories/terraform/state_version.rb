# frozen_string_literal: true

FactoryBot.define do
  factory :terraform_state_version, class: 'Terraform::StateVersion' do
    terraform_state factory: :terraform_state, traits: :versioned
    created_by_user factory: :user

    sequence(:version)

    trait :with_file do
      file { fixture_file_upload('spec/fixtures/terraform/terraform.tfstate', 'application/json') }
    end
  end
end
