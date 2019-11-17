# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  before_action :load_user, only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]

  def new
  end

  def create
    form_data = params[:password_reset]
    email = form_data[:email] if form_data
    @user = User.find_by(email: email.downcase) if email
    if @user&.activated?
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = "Reset email sent to #{@user.email.inspect}.  " \
        "Look for one with the subject \"Rating Stone Password Reset\"."
      redirect_to(root_url)
    else
      flash.now[:danger] = "Invalid or unknown email #{email.inspect} or " \
        "user not activated."
      render('new')
    end
  end

  def edit
  end

  def update
    if params[:user][:password].empty?
      @user.errors.add(:password, "can't be empty")
      render('edit')
    elsif @user.update(user_params)
      log_in(@user)
      @user.update_attribute(:reset_digest, nil) # Only one use per reset.
      flash[:success] = "Password has been reset."
      redirect_to(@user)
    else
      render('edit')
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  # Before filters.

  # Sets up @user from the passed in e-mail address.  @user nil if not found.
  def load_user
    email = params[:email]
    @user = User.find_by(email: email) if email
    @user.reset_token = params[:id] if @user # Save token for http->https url.
  end

  # Confirms a valid user and matching password reset token.
  def valid_user
    return true if @user&.activated? &&
      @user.authenticated?(:reset, params[:id])
    flash[:danger] = "Invalid password reset ignored."
    redirect_to(root_url)
  end

  # Checks expiration of reset token.
  def check_expiration
    if @user.password_reset_expired?
      flash[:danger] = "Password reset has expired."
      redirect_to(new_password_reset_url)
    end
  end
end
