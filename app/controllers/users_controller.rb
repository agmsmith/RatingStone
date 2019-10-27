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
      # Handle a successful save.
    else # Bad inputs, ask the user to redo the form.
      render('new')
    end
  end

  private

  def user_params # Sanitise the inputs from the submitted form data.
    params.require(:user).permit(:name, :email, :password,
      :password_confirmation)
  end
end
