# frozen_string_literal: true

class LedgerGroupsController < LedgerObjectsController
  def index
    @ledger_objects = LedgerSubgroup.all.paginate(page: params[:page])
  end

  def show
    @ledger_object = LedgerSubgroup.find_by(id: params[:id]) # Can be nil.
  end

  # See parent class for generic edit() method.

  # See parent class for generic update() method.

  private

  def sanitised_params # Sanitise the inputs from the submitted form data.
    params.require(:ledger_subgroup).permit(:name, :description)
  end
end
