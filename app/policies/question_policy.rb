class QuestionPolicy < ApplicationPolicy
  def index?   = same_tenant?
  def show?    = same_tenant?
  def create?  = same_tenant? && record.assessment.editable?
  def update?  = same_tenant? && record.assessment.editable?
  def destroy? = same_tenant? && record.assessment.editable?

  class Scope < Scope
    def resolve
      scope.for_tenant(recruiter.organization_id)
    end
  end

  private

  def same_tenant?
    record.organization_id == recruiter.organization_id
  end
end
