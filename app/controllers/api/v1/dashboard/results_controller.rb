module Api
  module V1
    module Dashboard
      class ResultsController < ApplicationController
        include Pagy::Backend
        before_action :set_result, only: [:show, :manual_review]

        def index
          render json: search_index_results
        rescue StandardError => e
          Rails.logger.error("Dashboard result search failed, falling back to SQL: #{e.message}")
          render json: database_fallback_results
        end

        def show
          authorize @result
          render json: ResultSerializer.render_as_hash(@result, view: :with_details)
        end

        def manual_review
          authorize @result
          detail = @result.result_details.find(params.require(:detail_id))

          detail.update!(
            score_awarded: params[:score_awarded].to_i,
            review_status: "reviewed",
            reviewer_notes: params[:reviewer_notes]
          )

          AggregateResultsJob.perform_later(candidate_session_id: @result.candidate_session_id, organization_id: @result.organization_id)

          render json: ResultSerializer.render_as_hash(@result.reload, view: :with_details)
        end

        private

        def search_index_results
          search_results = Elasticsearch::CandidateResultSearcher.new(
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

          result_ids = search_results[:results].map { |result| result["result_id"] }
          results_by_id = result_scope.where(id: result_ids).index_by(&:id)
          ordered_results = result_ids.filter_map { |id| results_by_id[id] }

          {
            results: ResultSerializer.render_as_hash(ordered_results, view: :with_details),
            meta: {
              current_page: search_results[:page],
              total_pages: (search_results[:total].to_f / search_results[:per_page]).ceil,
              total_count: search_results[:total],
              per_page: search_results[:per_page]
            },
            facets: search_results[:facets],
            search_backend: "elasticsearch"
          }
        end

        def database_fallback_results
          scope = result_scope.order(created_at: :desc)
          scope = scope.where(assessment_id: params[:assessment_id]) if params[:assessment_id].present?

          if params[:pass_fail].present? || params[:passed].present?
            pass_fail = params[:pass_fail].presence || params[:passed]
            scope = scope.where(passed: %w[true pass].include?(pass_fail.to_s))
          end

          if params[:completion_status].present? || params[:status].present?
            completion_status = params[:completion_status].presence || params[:status]
            scope = scope.joins(:candidate_session).where(candidate_sessions: { status: completion_status })
          end

          if params[:q].present?
            query = "%#{params[:q].downcase}%"
            scope = scope.joins(candidate_session: :invitation).where(
              "LOWER(invitations.candidate_name) LIKE :query OR LOWER(invitations.candidate_email) LIKE :query",
              query: query
            )
          end

          pagy, records = pagy(scope, limit: params[:per_page] || 20)

          {
            results: ResultSerializer.render_as_hash(records, view: :with_details),
            meta: pagination_meta(pagy),
            facets: {
              pass_fail: [],
              assessments: [],
              completion_status: []
            },
            search_backend: "database_fallback"
          }
        end

        def result_scope
          @result_scope ||= policy_scope(Result).includes(
            :assessment, :result_details,
            candidate_session: :invitation
          )
        end

        def set_result
          @result = policy_scope(Result).find(params[:id])
        end
      end
    end
  end
end
