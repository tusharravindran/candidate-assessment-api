class Current < ActiveSupport::CurrentAttributes
  attribute :recruiter, :organization

  def organization_id
    organization&.id
  end
end
