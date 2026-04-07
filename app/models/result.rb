class Result < ApplicationRecord
  include TenantScoped

  belongs_to :candidate_session
  belongs_to :organization
  belongs_to :assessment
  has_many :result_details, dependent: :destroy

  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }
  scope :pending_review, -> { where(pending_manual_review: true) }

  validates :candidate_session_id, uniqueness: true
  validate :candidate_session_belongs_to_organization
  validate :assessment_belongs_to_organization

  def finalized?
    status == "finalized"
  end

  private

  def candidate_session_belongs_to_organization
    return if candidate_session.blank? || organization_id.blank?
    return if candidate_session.organization_id == organization_id

    errors.add(:candidate_session, "must belong to the same organization")
  end

  def assessment_belongs_to_organization
    return if assessment.blank? || organization_id.blank?
    return if assessment.organization_id == organization_id

    errors.add(:assessment, "must belong to the same organization")
  end
end
