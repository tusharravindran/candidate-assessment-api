require "rails_helper"

RSpec.describe ScoringService do
  let(:organization) { create(:organization) }
  let(:recruiter) { create(:recruiter, organization: organization) }

  def build_session(assessment)
    invitation = create(:invitation, assessment: assessment, organization: organization, recruiter: recruiter)
    CandidateSession.create!(
      invitation: invitation,
      organization: organization,
      assessment: assessment,
      status: "submitted",
      started_at: Time.current,
      submitted_at: Time.current
    )
  end

  context "objective-only assessment" do
    let(:assessment) { create(:assessment, organization: organization, recruiter: recruiter, passing_score: 60) }
    let!(:q1) do
      q = create(:question, assessment: assessment, organization: organization, question_type: "multiple_choice", points: 5)
      create(:question_option, question: q, organization: organization, body: "Right", correct: true, position: 0)
      create(:question_option, question: q, organization: organization, body: "Wrong", correct: false, position: 1)
      q
    end
    let!(:q2) do
      q = create(:question, assessment: assessment, organization: organization, question_type: "multiple_choice", points: 5)
      create(:question_option, question: q, organization: organization, body: "Right", correct: true, position: 0)
      create(:question_option, question: q, organization: organization, body: "Wrong", correct: false, position: 1)
      q
    end

    before { assessment.publish! }

    it "passes when score meets passing_score" do
      session = build_session(assessment)
      Answer.create!(candidate_session: session, question: q1, organization: organization,
        selected_option_id: q1.question_options.find_by(correct: true).id)
      Answer.create!(candidate_session: session, question: q2, organization: organization,
        selected_option_id: q2.question_options.find_by(correct: true).id)

      result = described_class.new(session).call

      expect(result.total_score).to eq(10)
      expect(result.percentage.to_f).to eq(100.0)
      expect(result.passed).to be(true)
      expect(result.status).to eq("finalized")
      expect(result.pending_manual_review).to be(false)
    end

    it "fails when score is below passing_score" do
      session = build_session(assessment)
      Answer.create!(candidate_session: session, question: q1, organization: organization,
        selected_option_id: q1.question_options.find_by(correct: false).id)
      Answer.create!(candidate_session: session, question: q2, organization: organization,
        selected_option_id: q2.question_options.find_by(correct: false).id)

      result = described_class.new(session).call

      expect(result.total_score).to eq(0)
      expect(result.percentage.to_f).to eq(0.0)
      expect(result.passed).to be(false)
      expect(result.status).to eq("finalized")
    end

    it "scores partial correct answers" do
      session = build_session(assessment)
      Answer.create!(candidate_session: session, question: q1, organization: organization,
        selected_option_id: q1.question_options.find_by(correct: true).id)
      Answer.create!(candidate_session: session, question: q2, organization: organization,
        selected_option_id: q2.question_options.find_by(correct: false).id)

      result = described_class.new(session).call

      expect(result.total_score).to eq(5)
      expect(result.percentage.to_f).to eq(50.0)
    end

    it "scores 0 when no answers submitted" do
      session = build_session(assessment)

      result = described_class.new(session).call

      expect(result.total_score).to eq(0)
      expect(result.passed).to be(false)
    end
  end

  context "mixed objective + free-text assessment" do
    let(:assessment) { create(:assessment, organization: organization, recruiter: recruiter, passing_score: 60) }
    let!(:mcq) do
      q = create(:question, assessment: assessment, organization: organization, question_type: "multiple_choice", points: 2)
      create(:question_option, question: q, organization: organization, body: "Correct", correct: true, position: 0)
      create(:question_option, question: q, organization: organization, body: "Wrong", correct: false, position: 1)
      q
    end
    let!(:free_text) do
      create(:question, assessment: assessment, organization: organization, question_type: "free_text", points: 3)
    end

    before { assessment.publish! }

    it "marks pending_manual_review and does not set passed until reviewed" do
      session = build_session(assessment)
      Answer.create!(candidate_session: session, question: mcq, organization: organization,
        selected_option_id: mcq.question_options.find_by(correct: true).id)
      Answer.create!(candidate_session: session, question: free_text, organization: organization,
        free_text_answer: "My answer")

      result = described_class.new(session).call

      expect(result.total_score).to eq(2)
      expect(result.max_score).to eq(5)
      expect(result.percentage.to_f).to eq(40.0)
      expect(result.pending_manual_review).to be(true)
      expect(result.status).to eq("pending_manual_review")
      expect(result.passed).to be(false)
      expect(result.result_details.find_by!(question: free_text).review_status).to eq("pending_manual_review")
    end

    it "is idempotent — calling twice does not duplicate result details" do
      session = build_session(assessment)

      described_class.new(session).call
      described_class.new(session).call

      expect(session.reload.result.result_details.count).to eq(2)
    end
  end
end
