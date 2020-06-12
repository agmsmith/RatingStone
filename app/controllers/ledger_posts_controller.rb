# frozen_string_literal: true

class LedgerPostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  before_action :correct_user, only: :destroy

  def create
  end

  def destroy
    post_title = @ledger_post.content.truncate(50, separator: ' ')
    LedgerDelete.delete_records([@ledger_post], current_ledger_user,
      "Manual delete by user \"#{current_ledger_user.name}\".")
    feedback_text = "LedgerPost \"#{post_title}\" deleted"
    vcount = @ledger_post.all_versions.count
    feedback_text += " (#{vcount} versions included)" if vcount > 1
    flash[:success] = feedback_text + '.'
    redirect_back(fallback_location: root_url)
  end

  def show
    # Slightly more complex code to show an empty list when ID not found.
    @ledger_post = LedgerPost.where(id: params[:id])
    if @ledger_post.any?
      @ledger_post = @ledger_post.first.all_versions
        .paginate(page: params[:page])
    end
  end

  private

  def ledger_post_params
    params.require(:ledger_post).permit(:content)
  end

  def correct_user
    @ledger_post = LedgerPost.find(params[:id])
    redirect_to(root_url) if !current_ledger_user?(@ledger_post.creator)
  end
end
