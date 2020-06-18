# frozen_string_literal: true

class LedgerPostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  before_action :correct_user, only: [:destroy, :undelete, :update]

  def create
    @new_ledger_post = LedgerPost.new(ledger_post_params
      .merge(creator: current_ledger_user, type: :LedgerPost))
    if @new_ledger_post.save
      flash[:success] = "LedgerPost created!"
      redirect_to(root_url)
    else # Show error messages in the data entry form.
      render('static_pages/home')
    end
  end

  def destroy
    post_title = @ledger_post.content.truncate(50, separator: ' ')
    LedgerDelete.delete_records([@ledger_post], current_ledger_user,
      "Manual delete by user logged in from IP address " \
      "#{request.env['REMOTE_ADDR']}.")
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

  def undelete
    post_title = @ledger_post.content.truncate(50, separator: ' ')
    LedgerUndelete.undelete_records([@ledger_post], current_ledger_user,
      "Manual undelete by user logged in from IP address " \
      "#{request.env['REMOTE_ADDR']}.")
    feedback_text = "LedgerPost \"#{post_title}\" undeleted"
    vcount = @ledger_post.all_versions.count
    feedback_text += " (#{vcount} versions included)" if vcount > 1
    flash[:success] = feedback_text + '.'
    redirect_back(fallback_location: root_url)
  end

  private

  def ledger_post_params
    params.require(:ledger_post).permit(:content)
  end

  def correct_user
    @ledger_post = LedgerPost.find(params[:id])
    unless current_ledger_user?(@ledger_post.creator)
      flash[:error] =
        "You didn't create that post, so you can't update or (un)delete it."
      redirect_to(root_url)
    end
  end
end
