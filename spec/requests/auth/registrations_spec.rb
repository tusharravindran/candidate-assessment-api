require "rails_helper"

RSpec.describe "Recruiter registration", type: :request do
  describe "POST /api/v1/auth/sign_up" do
    it "creates a tenant organization and an admin recruiter" do
      email = "alice-#{SecureRandom.hex(4)}@acme.test"
      organization_name = "Acme Hiring #{SecureRandom.hex(4)}"

      expect do
        post "/api/v1/auth/sign_up",
          params: {
            organization_name: organization_name,
            recruiter: {
              name: "Alice Admin",
              email: email,
              password: "password123",
              password_confirmation: "password123"
            }
          },
          as: :json
      end.to change(Organization, :count).by(1).and change(Recruiter, :count).by(1)

      expect(response).to have_http_status(:created)

      recruiter = Recruiter.find_by!(email: email)
      expect(recruiter.admin?).to be(true)
      expect(recruiter.organization.name).to eq(organization_name)
      expect(json_body.dig("recruiter", "email")).to eq(email)
    end
  end
end
