require "rails_helper"

RSpec.describe ScoringService do
  it "scores objective answers and marks free-text answers for manual review" do
    organization = create(:organization)
    recruiter = create(:recruiter, organization: organization)
    assessment = create(:assessment, organization: organization, recruiter: recruiter, passing_score: 60)

    mcq = create(:question, assessment: assessment, organization: organization, question_type: "multiple_choice", points: 2)
    correct_option = create(:question_option, question: mcq, organization: organization, body: "Correct", correct: true, position: 0)
    create(:question_option, question: mcq, organization: organization, body: "Wrong", correct: false, position: 1)

    free_text = create(:question, assessment: assessment, organization: organization, question_type: "free_text", points: 3)
    assessment.publish!

    invitation = create(:invitation, assessment: assessment, organization: organization, recruiter: recruiter)
    session = CandidateSession.create!(
      invitation: invitation,
      organization: organization,
      assessment: assessment,
      status: "submitted",
      started_at: Time.current,
      submitted_at: Time.current
    )

    Answer.create!(
      candidate_session: session,
      question: mcq,
      organization: organization,
      selected_option_id: correct_option.id
    )
    Answer.create!(
      candidate_session: session,
      question: free_text,
      organization: organization,
      free_text_answer: "My free-text answer"
    )

    result = described_class.new(session).call

    expect(result.total_score).to eq(2)
    expect(result.max_score).to eq(5)
    expect(result.percentage.to_f).to eq(40.0)
    expect(result.pending_manual_review).to be(true)
    expect(result.status).to eq("pending_manual_review")
    expect(result.result_details.find_by!(question: free_text).review_status).to eq("pending_manual_review")
  end
end
