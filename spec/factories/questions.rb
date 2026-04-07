FactoryBot.define do
  factory :question do
    association :assessment
    organization { assessment.organization }
    sequence(:body) { |n| "Question #{n}?" }
    question_type { "multiple_choice" }
    points { 2 }
    sequence(:position) { |n| n }
  end
end
