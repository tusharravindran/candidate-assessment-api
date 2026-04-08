class Organization < ApplicationRecord
  has_many :recruiters, dependent: :destroy
  has_many :assessments, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :candidate_sessions, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :results, dependent: :destroy
  has_many :result_details, dependent: :destroy

  PLANS = %w[free pro enterprise].freeze

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :domain, uniqueness: true, allow_blank: true,
            format: { with: /\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}\z/i, allow_blank: true }
  validates :plan, inclusion: { in: PLANS }

  scope :active,    -> { where(active: true) }
  scope :suspended, -> { where(active: false) }

  before_validation :generate_slug, on: :create

  def suspend!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  def suspended?
    !active?
  end

  # Human-readable label used by RailsAdmin for association dropdowns
  def rails_admin_label
    "#{name} (#{slug})"
  end

  private

  def generate_slug
    self.slug ||= name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").strip.delete_prefix("-").delete_suffix("-")
  end
end
