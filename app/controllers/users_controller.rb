# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :logged_in_user, only: [:edit, :index, :update]
  before_action :correct_user, only: [:edit, :update]

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in(@user)
      flash[:success] = 'Welcome new user, to the Rating Stone Reputation System.'
      redirect_to(@user) # Show their profile page.
    else # Bad inputs.
      render('new') # Ask the user to redo the form.
    end
  end

  def edit
  end

  def index
    @users = User.paginate(page: params[:page])
  end

  def update
    if @user.update(user_params)
      flash[:success] = "Profile updated."
      redirect_to(@user)
    else
      render('edit')
    end
  end

  private

  def user_params # Sanitise the inputs from the submitted form data.
    params.require(:user).permit(:name, :email, :password,
      :password_confirmation)
  end

  # Before filters

  # Confirms a logged-in user.
  def logged_in_user
    unless logged_in?
      store_location # Come back here (if this is a GET) after login done.
      flash[:danger] = "Please log in."
      redirect_to(login_url)
    end
  end

  # Confirms we are editing the correct user.  Sets @user as a side effect.
  def correct_user
    @user = User.find(params[:id])
    unless current_user?(@user)
      flash[:danger] = "You were trying to edit a different user!  Start over."
      redirect_to(root_url)
    end
  end
end
