class FinalizeSubmissionJob < ApplicationJob
  queue_as :critical

  def perform(candidate_session_id:, organization_id:)
    with_organization(organization_id) do
      session = CandidateSession.includes(:assessment, :invitation, answers: :question).find(candidate_session_id)
      session.sync_timeout_state!
      return unless session.submission_complete?

      ScoreObjectiveAnswersJob.perform_later(candidate_session_id: candidate_session_id, organization_id: organization_id)
    end
  end
end
