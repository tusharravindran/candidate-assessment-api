class ResultSerializer < Blueprinter::Base
  identifier :id
  fields :total_score, :max_score, :percentage, :passed, :pending_manual_review, :status, :created_at

  field :pass_fail do |result|
    result.passed ? "pass" : "fail"
  end

  view :with_details do
    association :result_details, blueprint: ResultDetailSerializer
    field :candidate_session do |result|
      CandidateSessionSerializer.render_as_hash(result.candidate_session)
    end
    field :invitation do |result|
      InvitationSerializer.render_as_hash(result.candidate_session.invitation, view: :candidate)
    end
    field :assessment do |result|
      AssessmentSerializer.render_as_hash(result.assessment)
    end
  end
end
