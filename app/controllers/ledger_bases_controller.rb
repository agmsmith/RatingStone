# frozen_string_literal: true

class LedgerBasesController < ApplicationController
  # Note that some before actions are only used by subclasses.
  before_action :logged_in_user
  before_action :correct_user, only: [:destroy, :undelete, :edit, :update]

  def destroy # Also usually used by subclass controllers.
    unless @ledger_object
      flash[:danger] = "Can't find object ##{params[:id]} to delete."
      return redirect_back(fallback_location: root_url)
    end

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
    unless @ledger_object
      flash[:danger] = "Can't find object ##{params[:id]} to undelete."
      return redirect_back(fallback_location: root_url)
    end

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
    # Subclasses create their specific class instance in @ledger_object first.
    @ledger_object.assign_attributes(sanitised_params)
    if @ledger_object.save
      flash[:success] = "#{@ledger_object.base_s} created!"
      render('show')
    else # Since we may be coming from a non-data-entry page, expand errors.
      flash[:danger] = "Failed to create #{@ledger_object.type}: " +
        @ledger_object.errors.full_messages.join(', ') + '.'
      redirect_back(fallback_location: root_url)
    end
  end

  def new
  end

  def edit
    # Pre-existing object to be edited should be in @ledger_object.
    unless @ledger_object
      flash[:danger] = "Can't find object ##{params[:id]} to edit."
      redirect_back(fallback_location: root_url)
    end
  end

  def update
    # Subclasses create their specific class instance @ledger_object if needed
    # (initial @ledger_object is nil if the user is editing a new record rather
    # than an existing one) then call super.  Related link objects (like the
    # link to the original post for a reply) can be created on the fly from
    # values in params, see side_load_params method.
    if params[:preview]
      # Set the new values but don't save it, and keep same ID.  So you can
      # preview markdown text and continue editing it.
      @ledger_object.assign_attributes(sanitised_params)
      render('edit')
    else # Change the object by making a new version of it, new ID too.
      new_object = @ledger_object.append_version
      new_object.assign_attributes(sanitised_params)
      if new_object.save
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
    @ledger_object = LedgerBase.find_by(id: params[:id]) # Can be nil.
    if @ledger_object && !@ledger_object.creator_owner?(current_ledger_user)
      flash[:error] = "You're not the owner of that ledger object, " \
        "so you can't modify or delete it."
      redirect_to(root_url)
    end
  end

  ##
  # Subclasses will replace this to get their particular form field parameters.
  # Indeed, when previewing new objects (ones not yet in the database), the
  # parameters can include enough data to recreate related sub-objects (like
  # reply links to an original post, or group links to place a post in a group).
  def sanitised_params
    params.require(:ledger_object).permit(:string1, :string2)
  end
end
