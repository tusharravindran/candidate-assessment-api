require "rails_helper"

RSpec.describe Assessment, type: :model do
  describe "draft-only editing rules" do
    it "prevents content edits once the assessment is published" do
      assessment = create(:assessment)
      question = create(:question, assessment: assessment, organization: assessment.organization)
      create(:question_option, question: question, organization: assessment.organization, correct: true)

      assessment.publish!

      assessment.title = "Updated title"

      expect(assessment).not_to be_valid
      expect(assessment.errors.full_messages).to include("Only draft assessments can be edited")
    end
  end
end
