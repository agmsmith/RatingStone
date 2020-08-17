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
      # Set the new values but don't save it.  So you can preview markdown text.
      @ledger_object.assign_attributes(group_params)
      render('edit')
    elsif @ledger_object.update(group_params)
      flash[:success] = "#{@ledger_object.base_s} updated."
      redirect_to(ledger_group_path(@ledger_object))
    else # Failed to save, show error messages for field editing problems.
      render('edit')
    end
  end

  private

  def group_params # Sanitise the inputs from the submitted form data.
    params.require(:ledger_subgroup).permit(:name, :description)
  end
end
