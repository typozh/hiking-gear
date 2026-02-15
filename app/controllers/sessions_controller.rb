# frozen_string_literal: true

# Sessions Controller - handles login/logout
class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
    # Login form
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = 'Successfully logged in!'
      redirect_to root_path
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = 'Successfully logged out'
    redirect_to login_path
  end
end
