FactoryGirl.define do
  factory :epic do
    title { generate(:title) }
    group
    author

    trait :opened do
      state :opened
    end

    trait :closed do
      state :closed
    end
  end
end
