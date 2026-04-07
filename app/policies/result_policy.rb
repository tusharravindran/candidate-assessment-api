class ResultPolicy < ApplicationPolicy
  def index?         = true
  def show?          = same_tenant?
  def manual_review? = same_tenant? && admin?

  class Scope < Scope
    def resolve
      scope.for_tenant(recruiter.organization_id)
    end
  end
end
