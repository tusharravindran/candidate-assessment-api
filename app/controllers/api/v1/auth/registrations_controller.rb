module Api
  module V1
    module Auth
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json
        skip_before_action :verify_authenticity_token, raise: false
        before_action :configure_sign_up_params, only: [:create]

        def create
          ActiveRecord::Base.transaction do
            organization = Organization.create!(
              name: params[:organization_name] || "#{params[:recruiter]&.[](:name)}'s Organization"
            )

            build_resource(sign_up_params)
            resource.organization = organization
            resource.role = "admin"

            if resource.save
              sign_in(resource_name, resource)
              render json: {
                recruiter: RecruiterSerializer.render_as_hash(resource),
                message: "Account created successfully"
              }, status: :created
            else
              clean_up_passwords resource
              raise ActiveRecord::Rollback
            end
          end

          return if performed?

          render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: [e.message] }, status: :unprocessable_entity
        end

        protected

        def sign_up_params
          params.require(:recruiter).permit(:name, :email, :password, :password_confirmation)
        end

        def account_update_params
          params.require(:recruiter).permit(:name, :email, :password, :password_confirmation, :current_password)
        end

        private

        def configure_sign_up_params
          devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :organization_name])
        end
      end
    end
  end
end
