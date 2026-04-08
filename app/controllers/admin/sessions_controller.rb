class Admin::SessionsController < ActionController::Base
  include Devise::Controllers::Helpers
  include Devise::Controllers::UrlHelpers

  layout "admin_auth"

  before_action :redirect_if_signed_in, only: [:new, :create]

  def new
    @admin_user = AdminUser.new
  end

  def create
    admin = AdminUser.find_by(email: params.dig(:admin_user, :email)&.downcase)

    if admin&.valid_password?(params.dig(:admin_user, :password))
      sign_in(:admin_user, admin)
      redirect_to rails_admin.dashboard_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      @admin_user = AdminUser.new(email: params.dig(:admin_user, :email))
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out(:admin_user)
    redirect_to new_admin_user_session_path, notice: "Signed out successfully."
  end

  private

  def redirect_if_signed_in
    redirect_to rails_admin.dashboard_path, notice: "Already signed in." if warden.authenticated?(:admin_user)
  end
end
