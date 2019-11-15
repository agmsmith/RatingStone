# frozen_string_literal: true

class AccountActivationsController < ApplicationController
  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      log_in(user)
      flash[:success] = "Account activated.  Welcome to Rating Stone!"
      redirect_to(user)
    else
      flash[:danger] = "Invalid activation link.  " \
        "If you already used it, just log in."
      redirect_to(root_url)
    end
  end
end
