# frozen_string_literal: true

# Application Controller - base controller with authentication
class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  before_action :require_login

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    flash[:alert] = 'You must be logged in to access this page'
    redirect_to login_path
  end

  def skip_login_requirement
    # Override in controllers that don't require authentication
  end
end
