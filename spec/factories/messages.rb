FactoryBot.define do
  factory :message do
    association :conversation
    association :user
    body { Faker::Lorem.sentence(word_count: 8) }
  end
end
