module Api
  module V1
    class AssessmentsController < ApplicationController
      include Pagy::Backend

      before_action :set_assessment, only: [:show, :update, :destroy, :publish, :archive, :unarchive]

      def index
        assessments = policy_scope(Assessment)
          .includes(:questions, :invitations, :candidate_sessions, :results)
          .order(created_at: :desc)
        pagy, assessments = pagy(assessments)
        render json: {
          assessments: AssessmentSerializer.render_as_hash(assessments),
          meta: pagination_meta(pagy)
        }
      end

      def show
        authorize @assessment
        render json: AssessmentSerializer.render_as_hash(@assessment, view: :with_questions)
      end

      def create
        assessment = current_tenant.assessments.build(assessment_params)
        assessment.recruiter = current_recruiter
        authorize assessment

        if assessment.save
          render json: AssessmentSerializer.render_as_hash(assessment), status: :created
        else
          render json: { errors: assessment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @assessment
        if @assessment.update(assessment_params)
          render json: AssessmentSerializer.render_as_hash(@assessment)
        else
          render json: { errors: @assessment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @assessment
        @assessment.destroy!
        head :no_content
      end

      def publish
        authorize @assessment
        unless @assessment.draft?
          return render json: { error: "Only draft assessments can be published" }, status: :unprocessable_entity
        end

        unless @assessment.questions.exists?
          return render json: { error: "Assessment must have at least one question to publish" }, status: :unprocessable_entity
        end

        @assessment.publish!
        render json: AssessmentSerializer.render_as_hash(@assessment)
      end

      def archive
        authorize @assessment
        @assessment.archive!
        render json: AssessmentSerializer.render_as_hash(@assessment)
      end

      def unarchive
        authorize @assessment
        @assessment.unarchive!
        render json: AssessmentSerializer.render_as_hash(@assessment)
      end

      private

      def set_assessment
        @assessment = policy_scope(Assessment).find(params[:id])
      end

      def assessment_params
        params.require(:assessment).permit(:title, :description, :time_limit_minutes, :passing_score)
      end
    end
  end
end
