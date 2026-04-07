class Recruiter < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  belongs_to :organization
  has_many :assessments, dependent: :nullify
  has_many :invitations, dependent: :nullify

  enum role: { member: "member", admin: "admin" }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  def jwt_payload
    super.merge("organization_id" => organization_id, "role" => role)
  end
end
