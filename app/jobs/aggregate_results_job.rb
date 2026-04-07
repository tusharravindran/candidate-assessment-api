class AggregateResultsJob < ApplicationJob
  queue_as :default

  def perform(candidate_session_id:, organization_id:)
    with_organization(organization_id) do
      session = CandidateSession.includes(:result, :assessment, :organization).find(candidate_session_id)
      result = session.result
      return unless result

      details = result.result_details
      total_awarded = details.where.not(review_status: "pending_manual_review").sum(:score_awarded)
      max_possible = details.sum(:max_score)
      pct = max_possible.positive? ? (total_awarded.to_f / max_possible * 100).round(2) : 0
      has_pending = details.pending_review.exists?

      result.update!(
        total_score: total_awarded,
        max_score: max_possible,
        percentage: pct,
        passed: pct >= session.assessment.passing_score && !has_pending,
        pending_manual_review: has_pending,
        status: has_pending ? "pending_manual_review" : "finalized"
      )

      RefreshDashboardStatsJob.perform_later(organization_id: organization_id)
      IndexToElasticsearchJob.perform_later(candidate_session_id: candidate_session_id, organization_id: organization_id)
    end
  end
end
