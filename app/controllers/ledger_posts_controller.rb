# frozen_string_literal: true

class LedgerPostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  before_action :correct_user, only: :destroy

  def create
  end

  def destroy
    post_title = @ledger_post.content.truncate(50, separator: ' ')
    @ledger_post.destroy
    flash[:success] = "LedgerPost \"#{post_title}\" deleted."
    redirect_back(fallback_location: root_url)
  end

  private

  def ledger_post_params
    params.require(:ledger_post).permit(:content)
  end

  def correct_user
    @ledger_post = LedgerPost.find(params[:id])
    redirect_to(root_url) if current_ledger_user() != @ledger_post.creator
  end
end
