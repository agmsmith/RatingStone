# frozen_string_literal: true

module SessionsHelper
  # Logs in the given user (creates a session cookie storing the userid).
  def log_in(user)
    session[:user_id] = user.id
  end

  # Returns and caches the current logged-in user object (if any).
  def current_user
    if @current_user.nil? && session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
    end
  end

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    !current_user.nil?
  end

  def log_out
    session.delete(:user_id)
    @current_user = nil
  end
end
