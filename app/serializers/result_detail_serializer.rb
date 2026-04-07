class ResultDetailSerializer < Blueprinter::Base
  identifier :id
  fields :candidate_answer, :expected_answer, :score_awarded, :max_score, :review_status, :reviewer_notes
  field :question do |detail|
    {
      id: detail.question.id,
      body: detail.question.body,
      question_type: detail.question.question_type,
      points: detail.question.points,
      position: detail.question.position
    }
  end
end
