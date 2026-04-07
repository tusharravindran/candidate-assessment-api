class ScoringService
  def initialize(candidate_session)
    @session = candidate_session
  end

  def call
    result = find_or_create_result
    score_all_answers(result)
    finalize_result(result)
    result
  end

  private

  def find_or_create_result
    @session.result || @session.create_result!(
      organization: @session.organization,
      assessment: @session.assessment,
      max_score: total_possible_score
    )
  end

  def total_possible_score
    @session.assessment.questions.sum(:points)
  end

  def score_all_answers(result)
    has_free_text = false

    @session.assessment.questions.includes(:question_options).ordered.each do |question|
      answer = @session.answers.detect { |item| item.question_id == question.id }
      detail = find_or_build_detail(result, question)

      if question.free_text?
        has_free_text ||= answer&.free_text_answer.present?
        detail.review_status = answer&.free_text_answer.present? ? "pending_manual_review" : "not_required"
        detail.candidate_answer = answer&.free_text_answer
        detail.max_score = question.points
        detail.score_awarded = 0
      elsif question.objective?
        score_objective(detail, answer, question)
      end

      detail.save!
    end

    result.update!(pending_manual_review: has_free_text)
  end

  def score_objective(detail, answer, question)
    correct = question.correct_option
    selected = answer&.selected_option

    detail.expected_answer = correct&.body
    detail.candidate_answer = selected&.body
    detail.max_score = question.points
    detail.review_status = "not_required"

    if correct && selected && correct.id == selected.id
      detail.score_awarded = question.points
    else
      detail.score_awarded = 0
    end
  end

  def find_or_build_detail(result, question)
    result.result_details.find_or_initialize_by(
      question: question,
      organization: @session.organization
    )
  end

  def finalize_result(result)
    result.reload
    objective_score = result.result_details.where.not(review_status: "pending_manual_review").sum(:score_awarded)
    total = result.result_details.sum(:max_score)
    pct = total.positive? ? (objective_score.to_f / total * 100).round(2) : 0
    pending_manual_review = result.result_details.pending_review.exists?

    result.update!(
      total_score: objective_score,
      max_score: total,
      percentage: pct,
      passed: pct >= @session.assessment.passing_score && !pending_manual_review,
      pending_manual_review: pending_manual_review,
      status: pending_manual_review ? "pending_manual_review" : "finalized"
    )
  end
end
