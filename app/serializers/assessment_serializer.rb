class AssessmentSerializer < Blueprinter::Base
  identifier :id
  fields :title, :description, :time_limit_minutes, :passing_score, :status, :created_at, :updated_at

  field :total_invited do |assessment|
    assessment.invitations.count
  end

  field :total_completed do |assessment|
    assessment.candidate_sessions.where(status: %w[submitted auto_submitted expired]).count
  end

  field :completion_rate do |assessment|
    invited = assessment.invitations.count
    completed = assessment.candidate_sessions.where(status: %w[submitted auto_submitted expired]).count
    invited.zero? ? 0 : ((completed.to_f / invited) * 100).round(2)
  end

  field :average_score do |assessment|
    (assessment.results.average(:percentage)&.to_f || 0).round(2)
  end

  field :pass_rate do |assessment|
    total_results = assessment.results.count
    passes = assessment.results.passed.count
    total_results.zero? ? 0 : ((passes.to_f / total_results) * 100).round(2)
  end

  view :with_questions do
    association :questions, blueprint: QuestionSerializer
  end
end
