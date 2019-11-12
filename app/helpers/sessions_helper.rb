# frozen_string_literal: true

module SessionsHelper
  # Logs in the given user temporarily (creates a session cookie
  # storing the userid).  Can also be considered logged in with
  # a permanent cookie and database digest field, see current_user().
  def log_in(user)
    session[:user_id] = user.id
    @current_user = user
  end

  # Remembers a user in a persistent cookie.
  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  # Returns and caches the current logged-in User object, returns nil if not
  # logged in.  Looks at both a temporary session cookie or permanent cookie
  # holding the User ID, with priority given to the session cookie.
  def current_user
    if @current_user.nil?
      if (user_id = session[:user_id])
        @current_user = User.find_by(id: user_id)
      end
      if @current_user.nil? && (user_id = cookies.signed[:user_id])
        user = User.find_by(id: user_id)
        if user&.authenticated?(cookies[:remember_token])
          # Also set the lighter weight session cookie to the same user so that
          # subsequent page lookups don't have to go through the authentication
          # mechanism again.
          log_in(user)
        end
      end
    end
    @current_user
  end

  # Returns true if the given user is the current non-nil user, false otherwise.
  def current_user?(user)
    !user.nil? && user == current_user
  end

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    !current_user.nil?
  end

  # Forgets a persistent session.
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # Logs out the current user, if any.
  def log_out
    forget(current_user) if current_user
    session.delete(:user_id)
    @current_user = nil
  end

  # Redirects to stored location (or to the default).
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # Stores the URL trying to be accessed, for later use (eg. after login done).
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
end
