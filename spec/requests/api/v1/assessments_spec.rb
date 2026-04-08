require "rails_helper"

RSpec.describe "Assessments API", type: :request do
  describe "GET /api/v1/assessments" do
    it "returns paginated tenant-scoped assessments" do
      organization = create(:organization)
      recruiter = create(
        :recruiter,
        organization: organization,
        email: "assessments-admin@example.com",
        password: "password123",
        password_confirmation: "password123",
        role: "admin"
      )
      create_list(:assessment, 3, organization: organization, recruiter: recruiter)

      post "/api/v1/auth/sign_in",
        params: {
          recruiter: {
            email: recruiter.email,
            password: "password123"
          }
        },
        as: :json

      token = response.headers["Authorization"]
      expect(token).to be_present

      get "/api/v1/assessments",
        params: { per_page: 2 },
        headers: { "Authorization" => token }

      expect(response).to have_http_status(:ok)
      expect(json_body["assessments"].size).to eq(2)
      expect(json_body["meta"]).to include(
        "current_page" => 1,
        "total_pages" => 2,
        "total_count" => 3,
        "per_page" => 2
      )
    end
  end
end
