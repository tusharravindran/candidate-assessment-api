class Answer < ApplicationRecord
  include TenantScoped

  belongs_to :candidate_session
  belongs_to :question
  belongs_to :organization

  validates :candidate_session_id, uniqueness: { scope: :question_id }
  validate :candidate_session_belongs_to_organization
  validate :question_belongs_to_organization
  validate :selected_option_belongs_to_question

  def selected_option
    question.question_options.find_by(id: selected_option_id)
  end

  private

  def candidate_session_belongs_to_organization
    return if candidate_session.blank? || organization_id.blank?
    return if candidate_session.organization_id == organization_id

    errors.add(:candidate_session, "must belong to the same organization")
  end

  def question_belongs_to_organization
    return if question.blank? || organization_id.blank?
    return if question.organization_id == organization_id

    errors.add(:question, "must belong to the same organization")
  end

  def selected_option_belongs_to_question
    return if selected_option_id.blank? || question.blank?
    return if question.question_options.where(id: selected_option_id).exists?

    errors.add(:selected_option_id, "must belong to the same question")
  end
end
