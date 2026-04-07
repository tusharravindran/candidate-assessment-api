class InvitationPolicy < ApplicationPolicy
  def index?   = true
  def show?    = same_tenant?
  def create?  = true
  def destroy? = same_tenant? && !record.used?

  class Scope < Scope
    def resolve
      scope.for_tenant(recruiter.organization_id)
    end
  end
end
