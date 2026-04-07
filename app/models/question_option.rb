class QuestionOption < ApplicationRecord
  include TenantScoped

  belongs_to :question
  belongs_to :organization

  validates :body, presence: true
  validate :question_belongs_to_organization

  scope :ordered, -> { order(:position) }

  before_validation :set_organization_from_question

  private

  def set_organization_from_question
    self.organization_id ||= question&.organization_id
  end

  def question_belongs_to_organization
    return if question.blank? || organization_id.blank?
    return if question.organization_id == organization_id

    errors.add(:question, "must belong to the same organization")
  end
end
