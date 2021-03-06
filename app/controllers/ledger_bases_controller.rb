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
      "#{request.env["REMOTE_ADDR"]}.", params[:reason]) # Reason can be nil.
    feedback_text = "Ledger Object " +
      @ledger_object.to_s.truncate(60, separator: " ") +
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
      "#{request.env["REMOTE_ADDR"]}.", params[:reason]) # Reason can be nil.
    feedback_text = "Ledger Object " +
      @ledger_object.to_s.truncate(60, separator: " ") +
      " undeleted"
    vcount = @ledger_object.all_versions.count
    feedback_text += " (#{vcount} versions included)" if vcount > 1
    flash[:success] = feedback_text + "."
    redirect_back(fallback_location: root_url)
  end

  def index
    @ledger_objects = LedgerBase.where(deleted: false,
      is_latest_version: true).order(created_at: :desc)
      .paginate(page: params[:page])
  end

  def show
    # Note @ledger_object can be nil for missing records or no ID specified.
    @ledger_object = LedgerBase.find_by(id: params[:id]) if params[:id]
  end

  # Don't really need this method, can use update without an ID to create a
  # new object and display the editing form instead.  Stock HTML RESTful meets
  # DRY!
  def create
    @ledger_object = nil
    update
  end

  def new
  end

  def edit
    # Pre-existing object to be edited should already be in @ledger_object.
    unless @ledger_object
      flash[:danger] = "Can't find object ##{params[:id]} to edit."
      redirect_back(fallback_location: root_url)
    end
    side_load_params(@ledger_object)
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
      side_load_params(@ledger_object)
      render("edit")
    else # Change the object by making a new version of it, new ID too.
      is_new = @ledger_object.id.nil?
      new_object = if is_new
        @ledger_object
      else # Existing record, make a new version of it.
        @ledger_object.append_version
      end
      new_object.assign_attributes(sanitised_params)
      side_load_params(new_object)
      success = true
      new_object.class.transaction do
        success = new_object.save if success
        success = side_save(new_object) if success
        raise ActiveRecord::Rollback unless success
      end
      if success
        flash[:success] = if is_new
          "New #{@ledger_object.base_s} created."
        else
          "#{@ledger_object.base_s} updated, new version is #{new_object.base_s}."
        end
        @ledger_object = new_object
        render("show")
      else # Failed to save, preserve error messages for field editing display.
        new_object.id = @ledger_object.id
        @ledger_object = new_object
        render("edit")
      end
    end
  end

  private

  ##
  # See if the current user is allowed to modify the optional ID'd object.
  def correct_user
    # Note that no ID specified or bad ID gives us a nil object.  We use the
    # nil object case for creating new objects in update().
    @ledger_object = LedgerBase.find_by(id: params[:id]) if params[:id]
    if @ledger_object && !@ledger_object.creator_owner?(current_ledger_user)
      flash[:error] = "You're not the owner of that ledger object, " \
        "so you can't modify or delete it."
      redirect_to(root_url)
    end
  end

  ##
  # Subclasses will override this to get their particular form field parameters.
  # Indeed, when previewing new objects (ones not yet in the database), the
  # parameters can include enough data to recreate related sub-objects (like
  # group links to place a post in a group).  However, use side_load_params for
  # those extra parameters; only ones related directly to @ledger_object should
  # be filtered from params here (the result of this method is used in a
  # assign_attributes() call on @ledger_object).
  def sanitised_params
  end

  ##
  # For parameters that aren't exactly part of this new_object, side load
  # them into instance variables specific to the object class (such as which
  # groups a post is in).  They get used later to create link objects when the
  # main object is saved.  No, for several reasons we can't use nested
  # attributes to make the related records.  Subclasses override this, call
  # super and then do their work.
  def side_load_params(_new_object)
  end

  ##
  # For information that isn't exactly part of this @ledger_object, side save
  # it into related records specific to the object class (such as a
  # LinkGroupContent that specifies which group a post is in).  This will be
  # called after the main @ledger_object (actually a new version copy) has been
  # saved successfully (passed in as new_object), and inside a transaction, so
  # throwing an exception will undo the new object save too.  Subclasses should
  # override this and call super before doing their work.  Returns true if the
  # save was successful.  If the save failed, returns false and sets errors on
  # new_object using new_object.errors.add(fieldname, message).
  def side_save(_new_object)
    true
  end
end
