FactoryBot.define do
  factory :message_expense do
    association :message
    association :expense
  end
end
