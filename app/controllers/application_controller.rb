# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include SessionsHelper

  private

  # Confirms a logged-in user.  Otherwise redirects to error page.
  def logged_in_user
    unless logged_in?
      store_location # Come back here (if this is a GET) after login done.
      flash[:danger] = "Please log in."
      redirect_to(login_url)
    end
  end
end
