class IndexToElasticsearchJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(candidate_session_id:, organization_id:)
    with_organization(organization_id) do
      session = CandidateSession.includes(:result, :assessment, :invitation, :organization).find(candidate_session_id)
      return unless session.result

      Elasticsearch::CandidateResultIndexer.index_result(session.result)
    end
  rescue => e
    Rails.logger.error("ES indexing failed for session #{candidate_session_id}: #{e.message}")
    raise e
  end
end
