class AdminUser < ApplicationRecord
  # Platform-level administrator. No tenant scoping, no JWT.
  # Authenticates via session cookie through the /admin engine only.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable

  validates :email, presence: true, uniqueness: true
end
