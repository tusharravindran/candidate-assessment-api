require "rails_helper"

RSpec.describe "Assessments API", type: :request do
  let(:organization) { create(:organization) }
  let(:recruiter) do
    create(:recruiter, organization: organization, email: "recruiter@example.com",
      password: "password123", password_confirmation: "password123", role: "admin")
  end
  let(:token) { sign_in_recruiter(recruiter) }
  let(:auth_headers) { { "Authorization" => token } }

  describe "GET /api/v1/assessments" do
    it "returns paginated tenant-scoped assessments" do
      create_list(:assessment, 3, organization: organization, recruiter: recruiter)

      get "/api/v1/assessments", params: { per_page: 2 }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_body["assessments"].size).to eq(2)
      expect(json_body["meta"]).to include(
        "current_page" => 1,
        "total_pages" => 2,
        "total_count" => 3,
        "per_page" => 2
      )
    end

    it "does not return another tenant's assessments" do
      other_org = create(:organization)
      other_recruiter = create(:recruiter, organization: other_org)
      create(:assessment, organization: other_org, recruiter: other_recruiter)
      create(:assessment, organization: organization, recruiter: recruiter)

      get "/api/v1/assessments", headers: auth_headers

      expect(json_body["assessments"].size).to eq(1)
      expect(json_body["assessments"].first["id"]).not_to be_nil
    end
  end

  describe "POST /api/v1/assessments" do
    it "creates a draft assessment" do
      post "/api/v1/assessments",
        params: { assessment: { title: "Ruby Test", description: "Desc", time_limit_minutes: 30, passing_score: 70 } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["status"]).to eq("draft")
      expect(json_body["title"]).to eq("Ruby Test")
    end
  end

  describe "Assessment lifecycle" do
    let(:assessment) { create(:assessment, organization: organization, recruiter: recruiter) }
    let(:question) { create(:question, assessment: assessment, organization: organization) }

    before { create(:question_option, question: question, organization: organization, correct: true, body: "A", position: 0) }

    describe "POST /api/v1/assessments/:id/publish" do
      it "publishes a draft assessment that has questions" do
        post "/api/v1/assessments/#{assessment.id}/publish", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_body["status"]).to eq("published")
      end

      it "rejects publishing an assessment with no questions" do
        empty_assessment = create(:assessment, organization: organization, recruiter: recruiter)

        post "/api/v1/assessments/#{empty_assessment.id}/publish", headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_body["error"]).to match(/question/i)
      end

      it "rejects publishing an already-published assessment" do
        assessment.publish!

        post "/api/v1/assessments/#{assessment.id}/publish", headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "POST /api/v1/assessments/:id/archive" do
      it "archives a published assessment" do
        assessment.publish!

        post "/api/v1/assessments/#{assessment.id}/archive", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_body["status"]).to eq("archived")
      end

      it "archives a draft assessment" do
        post "/api/v1/assessments/#{assessment.id}/archive", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_body["status"]).to eq("archived")
      end
    end

    describe "POST /api/v1/assessments/:id/unarchive" do
      it "unarchives an archived assessment back to draft" do
        assessment.archive!

        post "/api/v1/assessments/#{assessment.id}/unarchive", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json_body["status"]).to eq("draft")
      end
    end

    describe "cross-tenant protection" do
      it "cannot see or mutate another tenant's assessment" do
        other_org = create(:organization)
        other_recruiter = create(:recruiter, organization: other_org)
        other_assessment = create(:assessment, organization: other_org, recruiter: other_recruiter)

        get "/api/v1/assessments/#{other_assessment.id}", headers: auth_headers
        expect(response).to have_http_status(:not_found)

        post "/api/v1/assessments/#{other_assessment.id}/publish", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

def sign_in_recruiter(recruiter)
  post "/api/v1/auth/sign_in",
    params: { recruiter: { email: recruiter.email, password: "password123" } },
    as: :json
  response.headers["Authorization"]
end
