# frozen_string_literal: true

class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  before_action :correct_user, only: :destroy

  def create
    @new_micropost = current_user.microposts.build(micropost_params)
    @new_micropost.image.attach(params[:micropost][:image])
    if @new_micropost.save
      flash[:success] = "Micropost created!"
      redirect_to(root_url)
    else # Show error messages with wrong controller, fake static_pages one.
      @feed_items = current_user.feed.paginate(page: params[:page])
      render('static_pages/home')
    end
  end

  def destroy
    post_title = @micropost.content.truncate(50, separator: ' ')
    @micropost.destroy
    flash[:success] = "Micropost \"#{post_title}\" deleted."
    redirect_back(fallback_location: root_url)
  end

  private

  def micropost_params
    params.require(:micropost).permit(:content, :image)
  end

  def correct_user
    @micropost = current_user.microposts.find_by(id: params[:id])
    redirect_to(root_url) if @micropost.nil?
  end
end
