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
    @ledger_post = LedgerPost.find(params[:id]).all_versions
      .paginate(page: params[:page])
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
