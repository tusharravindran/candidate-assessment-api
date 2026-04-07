require "rails_helper"

RSpec.describe "Candidate sessions", type: :request do
  describe "POST /api/v1/candidate/session/:token/submit" do
    it "is idempotent after the first accepted submission" do
      organization = create(:organization)
      recruiter = create(:recruiter, organization: organization, role: "admin")
      assessment = create(:assessment, organization: organization, recruiter: recruiter, time_limit_minutes: 30)
      question = create(:question, assessment: assessment, organization: organization, question_type: "multiple_choice", points: 1)
      correct_option = create(:question_option, question: question, organization: organization, correct: true, body: "Yes", position: 0)
      create(:question_option, question: question, organization: organization, correct: false, body: "No", position: 1)
      assessment.publish!

      invitation = create(:invitation, assessment: assessment, organization: organization, recruiter: recruiter)

      post "/api/v1/candidate/session/#{invitation.token}/start"

      expect(response).to have_http_status(:created)

      submit_payload = {
        answers: [
          {
            question_id: question.id,
            selected_option_id: correct_option.id
          }
        ]
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
