# frozen_string_literal: true

class StaticPagesController < ApplicationController
  def about
  end

  def contact
  end

  def help
  end

  def home
    if logged_in?
      @new_micropost = current_user.microposts.build
      @feed_items = current_user.feed.paginate(page: params[:page])
    end
  end
end
