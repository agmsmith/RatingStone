# frozen_string_literal: true

class LedgerPostsController < LedgerObjectsController
  def create
    @ledger_object = LedgerPost.new
    super
  end

  # See parent class for generic edit() method.

  def index
    @ledger_objects = LedgerPost.where(deleted: false).order(:created_at)
      .paginate(page: params[:page])
  end

  # See parent class for generic show() method.

  # See parent class for generic update() method.

  private

  def sanitised_params # Sanitise the inputs from the submitted form data.
    params.require(:ledger_post).permit(:content)
  end
end
