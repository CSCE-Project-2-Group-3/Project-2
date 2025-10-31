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

      after(:build) do |expense, evaluator|
        # Ensure user is a member of the group
        expense.group.users << expense.user unless expense.group.users.include?(expense.user)

        # Set participant_ids to only include the user themselves for group expenses
        if expense.participant_ids.blank?
          expense.participant_ids = [ expense.user_id ]
        end
      end
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
