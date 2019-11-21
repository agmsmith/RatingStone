# frozen_string_literal: true

class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]

  def create
    @new_micropost = current_user.microposts.build(micropost_params)
    if @new_micropost.save
      flash[:success] = "Micropost created!"
      redirect_to(root_url)
    else # Show error messages with wrong controller, fake static_pages one.
      @feed_items = current_user.feed.paginate(page: params[:page])
      render('static_pages/home')
   end
  end

  def destroy
  end

  private

  def micropost_params
    params.require(:micropost).permit(:content)
  end
end
