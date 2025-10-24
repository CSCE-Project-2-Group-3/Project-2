FactoryBot.define do
  factory :conversation do
    association :user_a, factory: :user
    association :user_b, factory: :user
  end
end
