# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = 'Welcome new user, to the Rating Stone Reputation System.'
      redirect_to @user # Show their profile page.
    else # Bad inputs.
      render('new') # Ask the user to redo the form.
    end
  end

  private

  def user_params # Sanitise the inputs from the submitted form data.
    params.require(:user).permit(:name, :email, :password,
      :password_confirmation)
  end
end
