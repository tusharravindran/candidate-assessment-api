class AssessmentPolicy < ApplicationPolicy
  def index?   = true
  def show?    = same_tenant?
  def create?  = true
  def update?  = same_tenant? && record.editable?
  def destroy? = same_tenant? && record.draft?
  def publish? = same_tenant? && record.may_publish?
  def archive? = same_tenant? && record.may_archive?

  class Scope < Scope
    def resolve
      scope.for_tenant(recruiter.organization_id)
    end
  end
end
