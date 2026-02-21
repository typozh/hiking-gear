# frozen_string_literal: true

# Authentication helper methods for controller specs
module AuthenticationHelpers
  def login_as(user)
    session[:user_id] = user.id
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
end
