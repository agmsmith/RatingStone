# frozen_string_literal: true

class LedgerUsersController < LedgerBasesController
  def show
    @ledger_object = LedgerUser.find_by(id: params[:id]) # Can be nil.
    if @ledger_object
      redirect_to(@ledger_object.user)
    else
      flash[:danger] =
        "Can't show LedgerUser ##{params[:id]}, record doesn't exist."
      redirect_to(root_url)
    end
  end
end
