# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include SessionsHelper

  after_action :fix_nosniff

  # Only put in the X-Content-Type-Options=nosniff in the HTTP response header,
  # when the web browser is not BeOS's NetPositive.  We took it out of the
  # default headers, so it doesn't show up in error pages etc.  NetPositive
  # has a bug which interprets that header as Content-Type.  Its ID string:
  # "Mozilla/3.0 (compatible; NetPositive/2.2.1; BeOS)"
  def fix_nosniff
    agent = request.headers["HTTP_USER_AGENT"]
    if agent && !agent.include?("NetPositive/")
      response.headers["X-Content-Type-Options"] = "nosniff"
    end
  end

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
