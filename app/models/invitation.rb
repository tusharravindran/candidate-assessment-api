class Invitation < ApplicationRecord
  include TenantScoped

  belongs_to :organization
  belongs_to :assessment
  belongs_to :recruiter
  has_one :candidate_session, dependent: :destroy

  validates :candidate_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(used: false).where("expires_at > ?", Time.current) }

  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create
  validate :assessment_belongs_to_organization
  validate :recruiter_belongs_to_organization
  validate :assessment_must_be_published

  def expired?
    expires_at < Time.current
  end

  def usable?
    !used? && !expired?
  end

  def mark_used!
    update!(used: true)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.expires_at ||= 7.days.from_now
  end

  def assessment_belongs_to_organization
    return if assessment.blank? || organization_id.blank?
    return if assessment.organization_id == organization_id

    errors.add(:assessment, "must belong to the same organization")
  end

  def recruiter_belongs_to_organization
    return if recruiter.blank? || organization_id.blank?
    return if recruiter.organization_id == organization_id

    errors.add(:recruiter, "must belong to the same organization")
  end

  def assessment_must_be_published
    return if assessment.blank? || assessment.published?

    errors.add(:assessment, "must be published before sending invitations")
  end
end
