module Api
  module V1
    class SearchController < ApplicationController
      def candidates
        results = Elasticsearch::CandidateResultSearcher.new(
          organization_id: current_tenant.id,
          query: params[:q],
          filters: {
            assessment_id: params[:assessment_id],
            pass_fail: params[:pass_fail] || params[:passed],
            completion_status: params[:completion_status] || params[:status]
          },
          page: params[:page] || 1,
          per_page: params[:per_page] || 20,
          sort: params[:sort]
        ).call

        render json: results
      rescue => e
        Rails.logger.error("Elasticsearch search failed: #{e.message}")
        render json: { error: "Search unavailable", results: [], total: 0, facets: {} }, status: :service_unavailable
      end
    end
  end
end
