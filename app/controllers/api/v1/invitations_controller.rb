module Api
  module V1
    class InvitationsController < ApplicationController
      include Pagy::Backend
      before_action :set_invitation, only: [:show, :destroy]

      def index
        invitations = policy_scope(Invitation).includes(:assessment).order(created_at: :desc)
        pagy, invitations = pagy(invitations)
        render json: {
          invitations: InvitationSerializer.render_as_hash(invitations),
          meta: pagination_meta(pagy)
        }
      end

      def show
        authorize @invitation
        render json: InvitationSerializer.render_as_hash(@invitation)
      end

      def create
        assessment = current_tenant.assessments.find(invitation_params[:assessment_id])

        invitation = current_tenant.invitations.build(
          invitation_params.except(:assessment_id).merge(
            assessment: assessment,
            recruiter: current_recruiter
          )
        )
        authorize invitation

        if invitation.save
          render json: InvitationSerializer.render_as_hash(invitation), status: :created
        else
          render json: { errors: invitation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @invitation
        @invitation.destroy!
        head :no_content
      end

      private

      def set_invitation
        @invitation = policy_scope(Invitation).find(params[:id])
      end

      def invitation_params
        params.require(:invitation).permit(:candidate_email, :candidate_name, :assessment_id, :expires_at)
      end
    end
  end
end
