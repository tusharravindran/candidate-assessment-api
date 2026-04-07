module TenantScoped
  extend ActiveSupport::Concern

  included do
    default_scope do
      if Current.organization_id.present?
        where(organization_id: Current.organization_id)
      else
        all
      end
    end

    validates :organization_id, presence: true
    before_validation :assign_current_organization, on: :create
  end

  class_methods do
    def for_tenant(organization_or_id = Current.organization_id)
      organization_id = organization_or_id.respond_to?(:id) ? organization_or_id.id : organization_or_id
      return all if organization_id.blank?

      unscope(where: :organization_id).where(organization_id: organization_id)
    end
  end

  private

  def assign_current_organization
    self.organization_id ||= Current.organization_id
  end
end
