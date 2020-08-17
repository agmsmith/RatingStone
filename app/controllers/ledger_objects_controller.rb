# frozen_string_literal: true

class LedgerObjectsController < ApplicationController
  # Note that some before actions are only used by subclasses.
  before_action :logged_in_user, only: [:show, :index, :new, :create]
  before_action :correct_user, only: [:destroy, :undelete, :edit, :update]

  def destroy # Also usually used by subclass controllers.
    LedgerDelete.delete_records([@ledger_object], current_ledger_user,
      "Web site manual delete by user logged in from address " \
      "#{request.env['REMOTE_ADDR']}.", params[:reason]) # Reason can be nil.
    feedback_text = "Ledger Object " +
      @ledger_object.to_s.truncate(60, separator: ' ') +
      " deleted"
    vcount = @ledger_object.all_versions.count
    feedback_text += " (#{vcount} versions included)" if vcount > 1
    flash[:success] = feedback_text + "."
    redirect_back(fallback_location: root_url)
  end

  def undelete # Also usually used by subclass controllers.
    LedgerUndelete.undelete_records([@ledger_object], current_ledger_user,
      "Web site manual undelete by user logged in from address " \
      "#{request.env['REMOTE_ADDR']}.", params[:reason]) # Reason can be nil.
    feedback_text = "Ledger Object " +
      @ledger_object.to_s.truncate(60, separator: ' ') +
      " undeleted"
    vcount = @ledger_object.all_versions.count
    feedback_text += " (#{vcount} versions included)" if vcount > 1
    flash[:success] = feedback_text + "."
    redirect_back(fallback_location: root_url)
  end

  def index
    @ledger_objects = LedgerBase.all.paginate(page: params[:page])
  end

  def show
    @ledger_object = LedgerBase.find_by(id: params[:id]) # Can be nil.
  end

  def create
  end

  def new
  end

  def edit
  end

  def update
  end

  private

  ##
  # Verify that the user is logged in, then get the ledger object and make
  # sure that they have permission to modify it.  Sets @ledger_object
  def correct_user
    if logged_in?
      @ledger_object = LedgerBase.find(params[:id])
      unless @ledger_object&.creator_owner?(current_ledger_user)
        flash[:error] = "You're not the owner of that ledger object, " \
          "so you can't modify or delete it."
        redirect_to(root_url)
      end
    else # Redirect to an error message about not being logged in.
      logged_in_user
    end
  end
end
