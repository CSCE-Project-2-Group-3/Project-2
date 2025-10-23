FactoryBot.define do
  factory :expense do
    sequence(:title) { |n| "Expense #{n}" }
    amount { 10.0 }
    spent_on { Date.current }
    association :category
    association :user

    transient do
      participant_users { [] }
    end

    trait :with_group do
      association :group
    end

    after(:build) do |expense, evaluator|
      if evaluator.participant_users.present?
        expense.participant_ids = evaluator.participant_users.map(&:id)
      elsif expense.participant_ids.blank? && expense.user_id.present?
        expense.participant_ids = [ expense.user_id ]
      end
    end
  end
end
