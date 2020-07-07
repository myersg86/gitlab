# frozen_string_literal: true

FactoryBot.define do
  factory :background_migration_job, class: '::Gitlab::BackgroundMigrationJob' do
    name { 'TestJob' }
    start_id { 1 }
    end_id { 100 }
    status { :pending }
    arguments { [] }
  end

  trait :completed do
    status { :completed }
  end
end
