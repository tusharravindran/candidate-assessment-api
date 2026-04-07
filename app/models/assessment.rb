class Assessment < ApplicationRecord
  include AASM
  include TenantScoped

  belongs_to :organization
  belongs_to :recruiter
  has_many :questions, dependent: :destroy
  has_many :invitations, dependent: :restrict_with_error
  has_many :candidate_sessions, dependent: :restrict_with_error
  has_many :results, dependent: :restrict_with_error

  validates :title, presence: true
  validates :time_limit_minutes, numericality: { greater_than: 0 }
  validates :passing_score, numericality: { in: 0..100 }
  validates :status, presence: true

  aasm column: :status do
    state :draft, initial: true
    state :published
    state :archived

    event :publish do
      transitions from: :draft, to: :published, guard: :has_questions?
    end

    event :archive do
      transitions from: [:draft, :published], to: :archived
    end
  end

  validate :recruiter_belongs_to_organization
  validate :draft_only_for_content_edits, on: :update

  def editable?
    draft?
  end

  def immutable?
    published?
  end

  private

  def has_questions?
    questions.exists?
  end

  def recruiter_belongs_to_organization
    return if recruiter.blank? || organization_id.blank?
    return if recruiter.organization_id == organization_id

    errors.add(:recruiter, "must belong to the same organization")
  end

  def draft_only_for_content_edits
    return if draft?

    changed_fields = changes_to_save.keys - %w[status updated_at]
    return if changed_fields.empty?

    errors.add(:base, "Only draft assessments can be edited")
  end
end
