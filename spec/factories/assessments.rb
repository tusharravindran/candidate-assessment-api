FactoryBot.define do
  factory :assessment do
    organization
    sequence(:title) { |n| "Assessment #{n}" }
    description { "Assessment description" }
    time_limit_minutes { 45 }
    passing_score { 70 }
    status { "draft" }

    recruiter { build(:recruiter, organization: organization) }
  end
end
