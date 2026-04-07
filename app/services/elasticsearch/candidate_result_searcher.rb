module Elasticsearch
  class CandidateResultSearcher
    INDEX_NAME = ENV.fetch("ELASTICSEARCH_INDEX_NAME", "candidate_results").freeze

    def initialize(organization_id:, query: nil, filters: {}, page: 1, per_page: 20, sort: nil)
      @organization_id = organization_id
      @query = query
      @filters = filters
      @page = [page.to_i, 1].max
      @per_page = per_page.to_i.clamp(1, 100)
      @sort = sort
    end

    def call
      response = client.search(index: INDEX_NAME, body: build_query)
      {
        results: response.dig("hits", "hits")&.map { |h| h["_source"].merge("result_id" => h["_id"].to_i) } || [],
        total: response.dig("hits", "total", "value") || 0,
        page: @page,
        per_page: @per_page,
        facets: extract_facets(response["aggregations"] || {})
      }
    end

    private

    def build_query
      must_clauses = [
        { term: { tenant_id: @organization_id } }
      ]

      if @query.present?
        must_clauses << {
          multi_match: {
            query: @query,
            fields: ["candidate_name^2", "candidate_email", "assessment_title"],
            fuzziness: "AUTO"
          }
        }
      end

      filter_clauses = []
      filter_clauses << { term: { assessment_id: @filters[:assessment_id] } } if @filters[:assessment_id]
      filter_clauses << { term: { pass_fail: normalize_pass_fail(@filters[:pass_fail]) } } if @filters[:pass_fail].present?
      filter_clauses << { term: { completion_status: @filters[:completion_status] } } if @filters[:completion_status].present?

      sort_clause = case @sort
                    when "score_desc" then [{ score: "desc" }]
                    when "score_asc"  then [{ score: "asc" }]
                    when "date_desc"  then [{ submitted_at: "desc" }]
                    else [{ submitted_at: "desc" }]
                    end

      {
        query: {
          bool: {
            must: must_clauses,
            filter: filter_clauses
          }
        },
        sort: sort_clause,
        from: (@page - 1) * @per_page,
        size: @per_page,
        aggs: {
          pass_fail: { terms: { field: "pass_fail" } },
          by_assessment: { terms: { field: "assessment_id", size: 50 } },
          by_status: { terms: { field: "completion_status" } }
        }
      }
    end

    def normalize_pass_fail(value)
      return "pass" if value == true || value.to_s == "true" || value.to_s == "pass"
      return "fail" if value == false || value.to_s == "false" || value.to_s == "fail"

      value
    end

    def extract_facets(aggregations)
      {
        pass_fail: extract_buckets(aggregations.dig("pass_fail", "buckets")),
        assessments: extract_buckets(aggregations.dig("by_assessment", "buckets")),
        completion_status: extract_buckets(aggregations.dig("by_status", "buckets"))
      }
    end

    def extract_buckets(buckets)
      Array(buckets).map do |bucket|
        { key: bucket["key"], count: bucket["doc_count"] }
      end
    end

    def client
      Elasticsearch::Model.client
    end
  end
end
