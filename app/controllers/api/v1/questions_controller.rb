module Api
  module V1
    class QuestionsController < ApplicationController
      before_action :set_assessment, only: [:index, :create]
      before_action :set_question, only: [:show, :update, :destroy]

      def index
        questions = @assessment.questions.for_tenant(current_recruiter.organization_id).ordered
        render json: QuestionSerializer.render_as_hash(questions, view: :with_answers)
      end

      def show
        authorize @question
        render json: QuestionSerializer.render_as_hash(@question, view: :with_answers)
      end

      def create
        question = @assessment.questions.build(question_params)
        question.organization = current_tenant
        authorize question

        if question.save
          create_options(question)
          render json: QuestionSerializer.render_as_hash(question, view: :with_answers), status: :created
        else
          render json: { errors: question.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @question
        @question.update!(question_params)
        sync_options(@question)
        render json: QuestionSerializer.render_as_hash(@question, view: :with_answers)
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def destroy
        authorize @question
        @question.destroy!
        head :no_content
      end

      private

      def set_assessment
        @assessment = policy_scope(Assessment).find(params[:assessment_id])
      end

      def set_question
        @question = policy_scope(Question).find(params[:id])
      end

      def question_params
        params.require(:question).permit(:body, :question_type, :points, :position)
      end

      def create_options(question)
        options = params.dig(:question, :options) || params[:options]
        return unless options.present?

        options.each_with_index do |opt, idx|
          question.question_options.create!(
            body: opt[:body],
            correct: opt[:correct] || false,
            position: idx,
            organization: current_tenant
          )
        end
      end

      def sync_options(question)
        options = params.dig(:question, :options) || params[:options]
        return unless options.present?

        question.question_options.destroy_all
        create_options(question)
      end
    end
  end
end
