FactoryBot.define do
  factory :expense do
    sequence(:title) { |n| "Expense #{n}" }
    amount { 10.0 }
    spent_on { Date.current }
    association :category
    association :user

    trait :with_group do
      association :group
    end
  end
end
