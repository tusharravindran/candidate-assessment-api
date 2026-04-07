require "rails_helper"

RSpec.describe "Recruiter registration", type: :request do
  describe "POST /api/v1/auth/sign_up" do
    it "creates a tenant organization and an admin recruiter" do
      expect do
        post "/api/v1/auth/sign_up",
          params: {
            organization_name: "Acme Hiring",
            recruiter: {
              name: "Alice Admin",
              email: "alice@acme.test",
              password: "password123",
              password_confirmation: "password123"
            }
          }.to_json,
          headers: { "CONTENT_TYPE" => "application/json" }
      end.to change(Organization, :count).by(1).and change(Recruiter, :count).by(1)

      expect(response).to have_http_status(:created)

      recruiter = Recruiter.find_by!(email: "alice@acme.test")
      expect(recruiter.admin?).to be(true)
      expect(recruiter.organization.name).to eq("Acme Hiring")
      expect(json_body.dig("recruiter", "email")).to eq("alice@acme.test")
    end
  end
end
