class CandidateSession < ApplicationRecord
  include AASM
  include TenantScoped

  belongs_to :invitation
  belongs_to :organization
  belongs_to :assessment
  has_many :answers, dependent: :destroy
  has_one :result, dependent: :destroy

  validates :status, presence: true
  validates :invitation_id, uniqueness: true

  aasm column: :status do
    state :not_started, initial: true
    state :in_progress
    state :submitted
    state :auto_submitted
    state :expired

    event :start do
      transitions from: :not_started, to: :in_progress
      after do
        self.started_at = Time.current
        self.deadline_at = started_at + assessment.time_limit_minutes.minutes
        save!
      end
    end

    event :submit do
      transitions from: :in_progress, to: :submitted
      after { self.submitted_at = Time.current; save! }
    end

    event :auto_submit do
      transitions from: :in_progress, to: :auto_submitted
      after { self.submitted_at = Time.current; save! }
    end

    event :expire do
      transitions from: [:not_started, :in_progress], to: :expired
      after { self.submitted_at ||= Time.current; save! }
    end
  end

  validate :invitation_belongs_to_organization
  validate :assessment_belongs_to_organization

  def time_remaining_seconds
    return 0 unless in_progress? && deadline_at
    [deadline_at - Time.current, 0].max.to_i
  end

  def time_exceeded?
    deadline_at.present? && Time.current > deadline_at
  end

  def submission_complete?
    submitted? || auto_submitted? || expired?
  end

  def sync_timeout_state!
    return unless in_progress?
    return unless time_exceeded?

    auto_submit!
  end

  def attempt_open?
    not_started? || in_progress?
  end

  def end_time
    submitted_at || deadline_at
  end

  private

  def invitation_belongs_to_organization
    return if invitation.blank? || organization_id.blank?
    return if invitation.organization_id == organization_id

    errors.add(:invitation, "must belong to the same organization")
  end

  def assessment_belongs_to_organization
    return if assessment.blank? || organization_id.blank?
    return if assessment.organization_id == organization_id

    errors.add(:assessment, "must belong to the same organization")
  end
end
