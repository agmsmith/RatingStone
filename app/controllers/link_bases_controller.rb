# frozen_string_literal: true

class LinkBasesController < ApplicationController
  before_action :logged_in_user, only: [:create, :index, :show]
  before_action :correct_user, only:
    [:approve, :unapprove, :destroy, :undelete]

  def approve
    stock_do_marking(LedgerApprove, true, "approve", "approved")
  end

  def create
  end

  def destroy
    stock_do_marking(LedgerDelete, true, "delete", "deleted")
  end

  def index
    @link_objects = LinkBase.where(deleted: false).order(created_at: :desc)
      .paginate(page: params[:page])
  end

  def show
    @link_object = LinkBase.find_by(id: params[:id]) # Can be nil.
  end

  def unapprove
    stock_do_marking(LedgerApprove, false, "unapprove", "unapproved")
  end

  def undelete
    stock_do_marking(LedgerDelete, false, "undelete", "undeleted")
  end

  private

  ##
  # Make sure the logged in user has permission to delete or approve the link.
  def correct_user
    @link_object = LinkBase.find_by(id: params[:id])
    unless @link_object&.creator_owner?(current_ledger_user)
      flash[:error] = "You're not the owner of that link object, " \
        "so you can't modify or delete it."
      redirect_to(root_url)
    end
  end

  ##
  # Do the usual controller processing for approve/delete/unapprove/undelete.
  # First finds the Link object, then does the operation, then displays results.
  def stock_do_marking(operation_class, new_flag_state,
    verb_present, verb_past)
    @link_object = LinkBase.find_by(id: params[:id]) # Can be nil.
    unless @link_object
      flash[:danger] = "Can't find link ##{params[:id]} to #{verb_present}."
      return redirect_back(fallback_location: root_url)
    end
    result = operation_class.mark_records(
      [@link_object],
      new_flag_state,
      current_ledger_user,
      "Web site manual Link Object #{verb_present} " \
        "by user logged in from address " \
        "#{request.env["REMOTE_ADDR"]}.",
      params[:reason],
    ) # Reason can be nil.
    feedback_text = if result.nil?
      "No changes needed or you don't have permission to #{verb_present} " \
        "Link Object " + @link_object.to_s.truncate(80, separator: " ") + "."
    else
      "Link Object " + @link_object.to_s.truncate(80, separator: " ") +
        " #{verb_past}."
    end
    flash[:success] = feedback_text
    redirect_back(fallback_location: root_url)
  end
end
