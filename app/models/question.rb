class Question < ApplicationRecord
  include TenantScoped

  belongs_to :assessment
  belongs_to :organization
  has_many :question_options, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :result_details, dependent: :destroy

  QUESTION_TYPES = %w[multiple_choice true_false free_text].freeze

  validates :body, presence: true
  validates :question_type, inclusion: { in: QUESTION_TYPES }
  validates :points, numericality: { greater_than: 0 }

  scope :ordered, -> { order(:position) }

  before_validation :set_organization_from_assessment
  validate :assessment_belongs_to_organization
  validate :assessment_must_be_editable

  def objective?
    multiple_choice? || true_false?
  end

  def multiple_choice?
    question_type == "multiple_choice"
  end

  def true_false?
    question_type == "true_false"
  end

  def free_text?
    question_type == "free_text"
  end

  def correct_option
    question_options.find_by(correct: true)
  end

  private

  def set_organization_from_assessment
    self.organization_id ||= assessment&.organization_id
  end

  def assessment_belongs_to_organization
    return if assessment.blank? || organization_id.blank?
    return if assessment.organization_id == organization_id

    errors.add(:assessment, "must belong to the same organization")
  end

  def assessment_must_be_editable
    return if assessment.blank? || assessment.editable?

    errors.add(:assessment, "can only be changed while the assessment is in draft")
  end
end
