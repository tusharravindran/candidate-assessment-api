class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.tenant_scope(organization_id)
    where(organization_id: organization_id)
  end
end
