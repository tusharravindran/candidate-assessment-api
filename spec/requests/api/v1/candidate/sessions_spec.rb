require "rails_helper"

RSpec.describe "Candidate sessions", type: :request do
  let(:organization) { create(:organization) }
  let(:recruiter) { create(:recruiter, organization: organization, role: "admin") }

  let(:assessment) do
    a = create(:assessment, organization: organization, recruiter: recruiter, time_limit_minutes: 30, passing_score: 50)
    q = create(:question, assessment: a, organization: organization, question_type: "multiple_choice", points: 1)
    create(:question_option, question: q, organization: organization, correct: true, body: "Yes", position: 0)
    create(:question_option, question: q, organization: organization, correct: false, body: "No", position: 1)
    a.publish!
    a
  end

  let(:question) { assessment.questions.first }
  let(:correct_option) { question.question_options.find_by(correct: true) }
  let(:invitation) { create(:invitation, assessment: assessment, organization: organization, recruiter: recruiter) }

  describe "GET /api/v1/candidate/session/:token" do
    it "returns assessment details for a valid invitation" do
      get "/api/v1/candidate/session/#{invitation.token}"

      expect(response).to have_http_status(:ok)
      expect(json_body["assessment"]["id"]).to eq(assessment.id)
      expect(json_body["attempt_available"]).to be(true)
    end

    it "returns 410 for an expired invitation" do
      invitation.update_column(:expires_at, 1.day.ago)

      get "/api/v1/candidate/session/#{invitation.token}"

      expect(response).to have_http_status(:gone)
    end
  end

  describe "POST /api/v1/candidate/session/:token/start" do
    it "creates a session and marks the invitation used" do
      post "/api/v1/candidate/session/#{invitation.token}/start"

      expect(response).to have_http_status(:created)
      expect(json_body["status"]).to eq("in_progress")
      expect(invitation.reload.used).to be(true)
    end

    it "returns the existing in-progress session on repeat start" do
      post "/api/v1/candidate/session/#{invitation.token}/start"
      post "/api/v1/candidate/session/#{invitation.token}/start"

      expect(response).to have_http_status(:ok)
      expect(CandidateSession.where(invitation: invitation).count).to eq(1)
    end
  end

  describe "POST /api/v1/candidate/session/:token/autosave" do
    it "saves answers without submitting the session" do
      post "/api/v1/candidate/session/#{invitation.token}/start"

      post "/api/v1/candidate/session/#{invitation.token}/autosave",
        params: { answers: [{ question_id: question.id, selected_option_id: correct_option.id }] }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(json_body["message"]).to eq("Answers saved")
      expect(invitation.reload.candidate_session.status).to eq("in_progress")
    end
  end

  describe "POST /api/v1/candidate/session/:token/submit" do
    it "is idempotent after the first accepted submission" do
      post "/api/v1/candidate/session/#{invitation.token}/start"
      expect(response).to have_http_status(:created)

      submit_payload = {
        answers: [{ question_id: question.id, selected_option_id: correct_option.id }]
      }

      post "/api/v1/candidate/session/#{invitation.token}/submit",
        params: submit_payload.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:accepted)
      expect(json_body["message"]).to eq("Assessment submitted successfully")
      expect(enqueued_jobs.map { |job| job[:job] }).to include(FinalizeSubmissionJob)

      post "/api/v1/candidate/session/#{invitation.token}/submit",
        params: submit_payload.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:ok)
      expect(json_body["message"]).to eq("Assessment submission already accepted")
    end
  end
end
