require "rails_helper"

RSpec.describe "Recruiter sessions", type: :request do
  describe "POST /api/v1/auth/sign_in" do
    it "logs a recruiter in and returns a JWT auth header" do
      organization = create(:organization)
      recruiter = create(
        :recruiter,
        organization: organization,
        email: "admin@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      post "/api/v1/auth/sign_in",
        params: {
          recruiter: {
            email: recruiter.email,
            password: "password123"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to be_present
      expect(json_body.dig("recruiter", "email")).to eq(recruiter.email)
    end
  end
end
