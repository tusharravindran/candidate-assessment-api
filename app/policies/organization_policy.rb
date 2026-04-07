class OrganizationPolicy < ApplicationPolicy
  def show? = same_tenant?
  def update? = same_tenant? && admin?
end
