class Organization < ApplicationRecord
  has_many :recruiters, dependent: :destroy
  has_many :assessments, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :candidate_sessions, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :results, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").strip.delete_prefix("-").delete_suffix("-")
  end
end
