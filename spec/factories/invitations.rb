FactoryBot.define do
  factory :invitation do
    assessment
    organization { assessment.organization }
    recruiter { assessment.recruiter }
    sequence(:candidate_email) { |n| "candidate#{n}@example.com" }
    sequence(:candidate_name) { |n| "Candidate #{n}" }
    sequence(:token) { |n| "invite-token-#{n}" }
    expires_at { 7.days.from_now }
    used { false }
  end
end
