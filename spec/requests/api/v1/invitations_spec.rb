require "rails_helper"

RSpec.describe "Invitations API", type: :request do
  let(:organization) { create(:organization) }
  let(:recruiter) do
    create(:recruiter, organization: organization, email: "inv-recruiter@example.com",
      password: "password123", password_confirmation: "password123", role: "admin")
  end
  let(:assessment) do
    a = create(:assessment, organization: organization, recruiter: recruiter)
    create(:question, assessment: a, organization: organization).tap do |q|
      create(:question_option, question: q, organization: organization, correct: true, body: "A", position: 0)
    end
    a.publish!
    a
  end
  let(:token) { sign_in_as(recruiter) }
  let(:auth_headers) { { "Authorization" => token } }

  describe "POST /api/v1/invitations" do
    it "creates an invitation for a published assessment" do
      post "/api/v1/invitations",
        params: { invitation: { candidate_email: "alice@example.com", candidate_name: "Alice", assessment_id: assessment.id } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["candidate_email"]).to eq("alice@example.com")
    end

    it "rejects a duplicate invitation (same email + assessment)" do
      create(:invitation, assessment: assessment, organization: organization, recruiter: recruiter,
        candidate_email: "alice@example.com")

      post "/api/v1/invitations",
        params: { invitation: { candidate_email: "alice@example.com", candidate_name: "Alice", assessment_id: assessment.id } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"].join).to match(/already been invited/i)
    end

    it "rejects a duplicate regardless of email case" do
      create(:invitation, assessment: assessment, organization: organization, recruiter: recruiter,
        candidate_email: "Alice@Example.com")

      post "/api/v1/invitations",
        params: { invitation: { candidate_email: "alice@example.com", candidate_name: "Alice", assessment_id: assessment.id } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects invitation to an unpublished (draft) assessment" do
      draft = create(:assessment, organization: organization, recruiter: recruiter)

      post "/api/v1/invitations",
        params: { invitation: { candidate_email: "bob@example.com", candidate_name: "Bob", assessment_id: draft.id } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"].join).to match(/published/i)
    end

    it "cannot invite to another tenant's assessment" do
      other_org = create(:organization)
      other_recruiter = create(:recruiter, organization: other_org)
      other_assessment = create(:assessment, organization: other_org, recruiter: other_recruiter)

      post "/api/v1/invitations",
        params: { invitation: { candidate_email: "eve@example.com", assessment_id: other_assessment.id } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/invitations" do
    it "filters by assessment_id" do
      other_assessment = create(:assessment, organization: organization, recruiter: recruiter).tap do |a|
        create(:question, assessment: a, organization: organization).tap { |q|
          create(:question_option, question: q, organization: organization, correct: true, body: "A", position: 0)
        }
        a.publish!
      end

      inv1 = create(:invitation, assessment: assessment, organization: organization, recruiter: recruiter)
      create(:invitation, assessment: other_assessment, organization: organization, recruiter: recruiter)

      get "/api/v1/invitations", params: { assessment_id: assessment.id }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      ids = json_body["invitations"].map { |i| i["id"] }
      expect(ids).to include(inv1.id)
      expect(ids.size).to eq(1)
    end
  end

  describe "DELETE /api/v1/invitations/:id" do
    it "deletes an invitation" do
      inv = create(:invitation, assessment: assessment, organization: organization, recruiter: recruiter)

      delete "/api/v1/invitations/#{inv.id}", headers: auth_headers

      expect(response).to have_http_status(:no_content)
      expect(Invitation.exists?(inv.id)).to be(false)
    end
  end
end

def sign_in_as(recruiter)
  post "/api/v1/auth/sign_in",
    params: { recruiter: { email: recruiter.email, password: "password123" } },
    as: :json
  response.headers["Authorization"]
end
