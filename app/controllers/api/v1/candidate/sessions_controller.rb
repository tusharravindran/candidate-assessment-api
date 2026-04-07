module Api
  module V1
    module Candidate
      class SessionsController < ActionController::API
        before_action :set_invitation
        around_action :set_current_context
        before_action :set_session, only: [:autosave, :submit]

        rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
        rescue_from ActiveRecord::RecordNotFound, with: :not_found

        def show
          @invitation.candidate_session&.sync_timeout_state!

          render json: {
            invitation: InvitationSerializer.render_as_hash(@invitation, view: :candidate),
            assessment: AssessmentSerializer.render_as_hash(@invitation.assessment, view: :with_questions),
            session: @invitation.candidate_session ? CandidateSessionSerializer.render_as_hash(@invitation.candidate_session) : nil,
            attempt_available: @invitation.candidate_session.blank? || @invitation.candidate_session.attempt_open?,
            expires_at: @invitation.expires_at
          }
        end

        def start
          session = nil
          created = false

          @invitation.with_lock do
            existing_session = @invitation.candidate_session
            if existing_session.present?
              existing_session.sync_timeout_state!
              session = existing_session
            else
              raise ActiveRecord::RecordInvalid, @invitation unless @invitation.usable?

              session = CandidateSession.create!(
                invitation: @invitation,
                organization: @invitation.organization,
                assessment: @invitation.assessment,
                ip_address: request.remote_ip,
                user_agent: request.user_agent
              )
              created = true

              session.start!
              @invitation.mark_used!
            end
          end

          if session.submission_complete?
            return render json: {
              error: "This invitation has already been completed",
              session: CandidateSessionSerializer.render_as_hash(session)
            }, status: :gone
          end

          status = created ? :created : :ok
          render json: CandidateSessionSerializer.render_as_hash(session), status: status
        end

        def autosave
          save_answers(params[:answers] || [])
          @session.sync_timeout_state!

          if @session.auto_submitted?
            enqueue_finalization
            return render json: {
              message: "Time expired. Session auto-submitted.",
              session: CandidateSessionSerializer.render_as_hash(@session)
            }, status: :ok
          end

          return render_session_closed unless @session.in_progress?

          render json: { message: "Answers saved", saved_at: Time.current }, status: :ok
        end

        def submit
          if @session.submission_complete?
            return render json: {
              message: "Assessment submission already accepted",
              session: CandidateSessionSerializer.render_as_hash(@session),
              result: @session.result ? ResultSerializer.render_as_hash(@session.result, view: :with_details) : nil
            }, status: :ok
          end

          return render_session_closed unless @session.in_progress?

          save_answers(params[:answers] || [])

          if @session.time_exceeded?
            @session.auto_submit!
          else
            @session.submit!
          end

          enqueue_finalization
          render json: {
            message: "Assessment submitted successfully",
            session: CandidateSessionSerializer.render_as_hash(@session)
          }, status: :accepted
        end

        private

        def set_invitation
          @invitation = Invitation.includes(:assessment, :organization, :candidate_session).find_by!(token: params[:token])

          unless @invitation.usable? || @invitation.candidate_session.present?
            render json: { error: "This invitation has expired or already been used" }, status: :gone and return
          end
        end

        def set_session
          @session = @invitation.candidate_session
          return if @session

          render json: { error: "Session not started yet" }, status: :not_found
        end

        def save_answers(answers_params)
          return if @session.submission_complete?

          answers_params.each do |ans|
            next unless ans[:question_id]

            question = @session.assessment.questions.find_by(id: ans[:question_id])
            next unless question

            answer = @session.answers.find_or_initialize_by(
              question: question,
              organization: @session.organization
            )

            if question.free_text?
              answer.free_text_answer = ans[:free_text_answer]
            else
              answer.selected_option_id = ans[:selected_option_id]
            end

            answer.save!
          end
        end

        def enqueue_finalization
          FinalizeSubmissionJob.perform_later(candidate_session_id: @session.id, organization_id: @session.organization_id)
        end

        def render_session_closed
          render json: { error: "This session is no longer accepting answers (status: #{@session.status})" },
                 status: :unprocessable_entity
        end

        def set_current_context
          Current.set(organization: @invitation.organization) do
            yield
          end
        end

        def unprocessable_entity(exception)
          render json: { error: "Unprocessable Entity", message: exception.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
        end

        def not_found(exception)
          render json: { error: "Not Found", message: exception.message }, status: :not_found
        end
      end
    end
  end
end
