# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :group_push_rule do
    force_push_regex { 'feature\/.*' }
    deny_delete_tag { false }
    delete_branch_regex { 'bug\/.*' }
    group
  end
end
