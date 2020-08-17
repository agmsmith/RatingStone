# frozen_string_literal: true

class LedgerGroupsController < LedgerObjectsController
  def index
    @ledger_objects = LedgerSubgroup.all.paginate(page: params[:page])
  end

  def show
    @ledger_object = LedgerSubgroup.find_by(id: params[:id]) # Can be nil.
  end
end
