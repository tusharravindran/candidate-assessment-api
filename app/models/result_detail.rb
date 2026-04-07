class ResultDetail < ApplicationRecord
  include TenantScoped

  belongs_to :result
  belongs_to :question
  belongs_to :organization

  REVIEW_STATUSES = %w[not_required pending_manual_review reviewed].freeze
  validates :review_status, inclusion: { in: REVIEW_STATUSES }
  validates :question_id, uniqueness: { scope: :result_id }

  scope :pending_review, -> { where(review_status: "pending_manual_review") }

  validate :result_belongs_to_organization
  validate :question_belongs_to_organization

  private

  def result_belongs_to_organization
    return if result.blank? || organization_id.blank?
    return if result.organization_id == organization_id

    errors.add(:result, "must belong to the same organization")
  end

  def question_belongs_to_organization
    return if question.blank? || organization_id.blank?
    return if question.organization_id == organization_id

    errors.add(:question, "must belong to the same organization")
  end
end
