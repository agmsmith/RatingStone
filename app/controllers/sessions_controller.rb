# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
  end

  def create
    session = params[:session]
    email = session[:email] if session
    user = User.find_by(email: email.downcase) if email
    if user&.authenticate(session[:password])
      if user.activated?
        # Log the user in (save session cookie) and redirect to profile page.
        log_in(user)
        session[:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or(user)
      else
        flash[:warning] = "Account is not activated.  Check your email " \
          "for the activation link."
        redirect_to(root_url)
      end
    else
      # Create an error message.
      flash.now[:danger] = 'Invalid email/password combination'
      render('new')
    end
  end

  def destroy
    log_out
    redirect_to(root_url)
  end
end
