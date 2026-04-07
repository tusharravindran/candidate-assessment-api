FactoryBot.define do
  factory :assessment do
    association :organization
    association :recruiter, organization: organization
    sequence(:title) { |n| "Assessment #{n}" }
    description { "Assessment description" }
    time_limit_minutes { 45 }
    passing_score { 70 }
    status { "draft" }
  end
end
