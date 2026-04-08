require "rails_helper"

RSpec.describe "Questions API", type: :request do
  let(:organization) { create(:organization) }
  let(:recruiter) do
    create(:recruiter, organization: organization, email: "q-recruiter@example.com",
      password: "password123", password_confirmation: "password123", role: "admin")
  end
  let(:assessment) { create(:assessment, organization: organization, recruiter: recruiter) }
  let(:token) { sign_in_q(recruiter) }
  let(:auth_headers) { { "Authorization" => token } }

  describe "POST /api/v1/assessments/:assessment_id/questions" do
    it "creates a multiple choice question with options" do
      post "/api/v1/assessments/#{assessment.id}/questions",
        params: {
          question: {
            body: "What is Ruby?",
            question_type: "multiple_choice",
            points: 2,
            position: 1,
            options: [
              { body: "A language", correct: true },
              { body: "A gem", correct: false }
            ]
          }
        },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["body"]).to eq("What is Ruby?")
      expect(json_body["question_options"].size).to eq(2)
      expect(json_body["question_options"].count { |o| o["correct"] }).to eq(1)
    end

    it "creates a free-text question" do
      post "/api/v1/assessments/#{assessment.id}/questions",
        params: { question: { body: "Explain OOP.", question_type: "free_text", points: 5, position: 1 } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body["question_type"]).to eq("free_text")
    end

    it "cannot add a question to a published assessment" do
      create(:question, assessment: assessment, organization: organization).tap do |q|
        create(:question_option, question: q, organization: organization, correct: true, body: "A", position: 0)
      end
      assessment.publish!

      post "/api/v1/assessments/#{assessment.id}/questions",
        params: { question: { body: "New Q?", question_type: "multiple_choice", points: 1, position: 2 } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/questions/:id" do
    it "deletes a question from a draft assessment" do
      question = create(:question, assessment: assessment, organization: organization)

      delete "/api/v1/questions/#{question.id}", headers: auth_headers

      expect(response).to have_http_status(:no_content)
      expect(Question.exists?(question.id)).to be(false)
    end
  end
end

def sign_in_q(recruiter)
  post "/api/v1/auth/sign_in",
    params: { recruiter: { email: recruiter.email, password: "password123" } },
    as: :json
  response.headers["Authorization"]
end
