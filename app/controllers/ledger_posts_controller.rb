# frozen_string_literal: true

class LedgerPostsController < LedgerObjectsController
  def create
    @new_ledger_post = LedgerPost.new(sanitised_params
      .merge(creator_id: current_ledger_user.original_version_id,
      type: :LedgerPost))
    if @new_ledger_post.save
      flash[:success] = "LedgerPost created!"
      redirect_to(root_url)
    else # Show error messages in the data entry form.
      render('static_pages/home')
    end
  end

  def index
    @ledger_objects = LedgerPost.all.order(:id).paginate(page: params[:page])
  end

  private

  def sanitised_params
    params.require(:ledger_post).permit(:content)
  end
end
