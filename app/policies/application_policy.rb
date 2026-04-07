class ApplicationPolicy
  attr_reader :recruiter, :record

  def initialize(recruiter, record)
    raise Pundit::NotAuthorizedError, "Must be authenticated" unless recruiter
    @recruiter = recruiter
    @record = record
  end

  def index?   = false
  def show?    = false
  def create?  = false
  def update?  = false
  def destroy? = false

  class Scope
    attr_reader :recruiter, :scope

    def initialize(recruiter, scope)
      raise Pundit::NotAuthorizedError, "Must be authenticated" unless recruiter

      @recruiter = recruiter
      @scope = scope
    end

    def resolve
      scope.all
    end
  end

  private

  def same_tenant?
    record_org_id = record.respond_to?(:organization_id) ? record.organization_id : record.try(:id)
    record_org_id == recruiter.organization_id
  end

  def admin?
    recruiter.admin?
  end
end
