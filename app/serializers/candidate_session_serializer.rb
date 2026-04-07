class CandidateSessionSerializer < Blueprinter::Base
  identifier :id
  fields :status, :started_at, :submitted_at, :deadline_at, :created_at

  field :start_time do |session|
    session.started_at
  end

  field :end_time do |session|
    session.end_time
  end

  field :time_remaining_seconds do |session|
    session.time_remaining_seconds
  end

  field :assessment do |session|
    AssessmentSerializer.render_as_hash(session.assessment, view: :with_questions)
  end

  field :invitation do |session|
    {
      candidate_email: session.invitation.candidate_email,
      candidate_name: session.invitation.candidate_name
    }
  end
end
