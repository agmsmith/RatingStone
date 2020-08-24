# frozen_string_literal: true

class LedgerGroupsController < LedgerObjectsController
  def index
    @ledger_objects = LedgerSubgroup.all.paginate(page: params[:page])
  end

  def show
    @ledger_object = LedgerSubgroup.find_by(id: params[:id]) # Can be nil.
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
        redirect_to(ledger_group_path(new_object))
      else # Failed to save, show error messages for field editing problems.
        new_object.id = @ledger_object.id
        @ledger_object = new_object
        render('edit')
      end
    end
  end

  private

  def sanitised_params # Sanitise the inputs from the submitted form data.
    params.require(:ledger_subgroup).permit(:name, :description)
  end
end
