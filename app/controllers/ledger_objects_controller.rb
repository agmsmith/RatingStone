# frozen_string_literal: true

class LedgerObjectsController < ApplicationController
  # Note that some before actions are only used by subclasses.
  before_action :logged_in_user
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
    @ledger_object = LedgerBase.find_by(id: params[:id]) # Result can be nil.
  end

  def create
  end

  def new
  end

  def edit
    # Object to be edited already loaded into @ledger_object.
  end

  def update
    # Object to be edited already loaded into @ledger_object.
    if params[:preview]
      # Set the new values but don't save it, keep same ID.  So you can
      # preview markdown text.
      @ledger_object.assign_attributes(sanitised_params)
      render('edit')
    else # Change the object by making a new version of it, new ID too.
      new_object = @ledger_object.append_version
      if new_object.update(sanitised_params)
        flash[:success] = "#{@ledger_object.base_s} updated, " \
          "new version is #{new_object.base_s}."
        @ledger_object = new_object
        render('show')
      else # Failed to save, show error messages for field editing problems.
        new_object.id = @ledger_object.id
        @ledger_object = new_object
        render('edit')
      end
    end
  end

  private

  def correct_user
    @ledger_object = LedgerBase.find(params[:id])
    unless @ledger_object&.creator_owner?(current_ledger_user)
      flash[:error] = "You're not the owner of that ledger object, " \
        "so you can't modify or delete it."
      redirect_to(root_url)
    end
  end

  ##
  # Subclasses will replace this to get their particular field parameters.
  def sanitised_params # Sanitise the inputs from the submitted form data.
    params.require(:ledger_object).permit(:string1, :string2)
  end
end
