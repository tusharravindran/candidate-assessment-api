module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        respond_to :json
        skip_before_action :verify_authenticity_token, raise: false

        def create
          self.resource = warden.authenticate!(auth_options)
          unless resource&.persisted?
            return render json: { error: "Invalid credentials" }, status: :unauthorized
          end

          sign_in(resource_name, resource, store: false)

          render json: {
            recruiter: RecruiterSerializer.render_as_hash(resource),
            message: "Logged in successfully"
          }, status: :ok
        end

        def destroy
          sign_out(resource_name)
          render json: { message: "Logged out successfully" }, status: :ok
        end

        private

        def respond_with(resource, _opts = {})
          unless resource&.persisted?
            return render json: { error: "Invalid credentials" }, status: :unauthorized
          end

          render json: {
            recruiter: RecruiterSerializer.render_as_hash(resource),
            message: "Logged in successfully"
          }, status: :ok
        end

        def respond_to_on_destroy
          render json: { message: "Logged out successfully" }, status: :ok
        end
      end
    end
  end
end
