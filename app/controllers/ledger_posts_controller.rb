# frozen_string_literal: true

class LedgerPostsController < LedgerObjectsController
  def create
    @ledger_object = LedgerPost.new
    super
  end

  def index
    @ledger_objects = LedgerPost.where(deleted: false).order(:created_at)
      .paginate(page: params[:page])
  end

  private

  def sanitised_params
    params.require(:ledger_post).permit(:content)
  end
end
