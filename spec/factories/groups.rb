FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    sequence(:join_code) { |n| "CODE#{n.to_s.rjust(4, '0')}" }
  end
end
