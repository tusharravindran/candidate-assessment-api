FactoryBot.define do
  factory :question_option do
    association :question
    organization { question.organization }
    sequence(:body) { |n| "Option #{n}" }
    correct { false }
    sequence(:position) { |n| n }
  end
end
