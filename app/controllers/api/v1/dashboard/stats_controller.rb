module Api
  module V1
    module Dashboard
      class StatsController < ApplicationController
        def show
          org = current_tenant
          assessments = Assessment.for_tenant(org.id)
          sessions = CandidateSession.for_tenant(org.id)
          results = Result.for_tenant(org.id)
          completed_sessions = sessions.where(status: %w[submitted auto_submitted expired])
          total_invitations = Invitation.for_tenant(org.id).count
          completed_count = completed_sessions.count
          pass_count = results.passed.count
          average_score = results.average(:percentage)&.to_f || 0

          render json: {
            total_assessments: assessments.count,
            published_assessments: assessments.where(status: "published").count,
            total_invitations: total_invitations,
            total_sessions: sessions.count,
            completed_sessions: completed_count,
            completion_rate: total_invitations.zero? ? 0 : ((completed_count.to_f / total_invitations) * 100).round(2),
            average_score: average_score.round(2),
            pass_rate: results.count.zero? ? 0 : ((pass_count.to_f / results.count) * 100).round(2),
            total_results: results.count,
            passed_results: pass_count,
            pending_review: results.pending_review.count
          }
        end
      end
    end
  end
end
