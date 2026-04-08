class ApplicationController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_recruiter!
  before_action :check_organization_active!
  around_action :set_current_context

  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from AASM::InvalidTransition, with: :unprocessable_entity

  private

  def current_tenant
    current_recruiter&.organization
  end

  def pundit_user
    current_recruiter
  end

  # Block all API access if the organization has been suspended by a platform admin.
  # The JWT may still be valid — we re-check org status on every request so that
  # suspension takes effect immediately without waiting for token expiry.
  def check_organization_active!
    return unless current_recruiter

    unless current_tenant&.active?
      render json: {
        error: "Account Suspended",
        message: "Your organization account has been suspended. Please contact support."
      }, status: :forbidden
    end
  end

  def forbidden(e = nil)
    render json: { error: "Forbidden", message: e&.message || "You are not authorized to perform this action" }, status: :forbidden
  end

  def not_found(e = nil)
    render json: { error: "Not Found", message: e&.message || "Resource not found" }, status: :not_found
  end

  def bad_request(e = nil)
    render json: { error: "Bad Request", message: e&.message }, status: :bad_request
  end

  def unprocessable_entity(e = nil)
    render json: { error: "Unprocessable Entity", message: e&.message }, status: :unprocessable_entity
  end

  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end

  def set_current_context
    Current.set(recruiter: current_recruiter, organization: current_tenant) do
      yield
    end
  end
end
