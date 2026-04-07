module Elasticsearch
  class CandidateResultIndexer
    INDEX_NAME = ENV.fetch("ELASTICSEARCH_INDEX_NAME", "candidate_results").freeze

    def self.create_index!
      client.indices.create(
        index: INDEX_NAME,
        body: {
          settings: { number_of_shards: 1, number_of_replicas: 0 },
          mappings: {
            properties: {
              tenant_id: { type: "keyword" },
              assessment_id: { type: "long" },
              assessment_title: { type: "text", analyzer: "standard" },
              candidate_name: { type: "text", analyzer: "standard" },
              candidate_email: { type: "text", analyzer: "standard", fields: { keyword: { type: "keyword" } } },
              score: { type: "float" },
              pass_fail: { type: "keyword" },
              completion_status: { type: "keyword" },
              submitted_at: { type: "date" }
            }
          }
        }
      )
    rescue ::Elasticsearch::Transport::Transport::Errors::BadRequest => e
      raise e unless e.message.include?("resource_already_exists_exception")
    end

    def self.index_result(result)
      session = result.candidate_session
      invitation = session.invitation

      client.index(
        index: INDEX_NAME,
        id: result.id,
        body: {
          tenant_id: result.organization_id,
          assessment_id: result.assessment_id,
          assessment_title: result.assessment.title,
          candidate_name: invitation.candidate_name,
          candidate_email: invitation.candidate_email,
          score: result.percentage,
          pass_fail: result.passed ? "pass" : "fail",
          completion_status: session.status,
          submitted_at: session.submitted_at&.iso8601
        }
      )
    end

    def self.bulk_index_results(results)
      payload = results.flat_map do |result|
        [
          { index: { _index: INDEX_NAME, _id: result.id } },
          {
            tenant_id: result.organization_id,
            assessment_id: result.assessment_id,
            assessment_title: result.assessment.title,
            candidate_name: result.candidate_session.invitation.candidate_name,
            candidate_email: result.candidate_session.invitation.candidate_email,
            score: result.percentage,
            pass_fail: result.passed ? "pass" : "fail",
            completion_status: result.candidate_session.status,
            submitted_at: result.candidate_session.submitted_at&.iso8601
          }
        ]
      end

      client.bulk(body: payload) if payload.any?
    end

    def self.delete_result(result_id)
      client.delete(index: INDEX_NAME, id: result_id)
    rescue ::Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def self.client
      Elasticsearch::Model.client
    end
  end
end
