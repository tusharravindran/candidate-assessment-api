FactoryBot.define do
  factory :recruiter do
    association :organization
    sequence(:email) { |n| "recruiter#{n}@example.com" }
    sequence(:name) { |n| "Recruiter #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    role { "member" }
  end
end
