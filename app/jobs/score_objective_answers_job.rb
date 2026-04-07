class ScoreObjectiveAnswersJob < ApplicationJob
  queue_as :critical

  def perform(candidate_session_id:, organization_id:)
    with_organization(organization_id) do
      session = CandidateSession.includes(
        :assessment,
        :organization,
        :invitation,
        answers: { question: :question_options }
      ).find(candidate_session_id)

      ScoringService.new(session).call
      AggregateResultsJob.perform_later(candidate_session_id: candidate_session_id, organization_id: organization_id)
    end
  end
end
