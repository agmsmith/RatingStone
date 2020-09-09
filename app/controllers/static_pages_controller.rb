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
      @ledger_post = LedgerPost.new(creator: current_ledger_user)
      @ledger_feed_items = current_ledger_user.feed
        .paginate(page: params[:page])
    end
  end
end
