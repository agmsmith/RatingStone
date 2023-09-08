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
      @pagy, @ledger_feed_items = pagy(current_ledger_user.feed)
    end
  end
end
