# frozen_string_literal: true

class LedgerPostsController < LedgerObjectsController
  def create
    @new_ledger_post = LedgerPost.new(ledger_post_params
      .merge(creator_id: current_ledger_user.original_version_id,
      type: :LedgerPost))
    if @new_ledger_post.save
      flash[:success] = "LedgerPost created!"
      redirect_to(root_url)
    else # Show error messages in the data entry form.
      render('static_pages/home')
    end
  end

  def edit
    # Object to be edited already loaded into @ledger_object.
  end

  def index
    @ledger_objects = LedgerPost.all.paginate(page: params[:page])
  end

  def show
    # Slightly more complex code to show an empty list when ID not found.
    @ledger_objects = LedgerPost.where(id: params[:id])
    if @ledger_objects.any?
      @ledger_objects = @ledger_objects.first.all_versions
        .paginate(page: params[:page])
    end
  end

  def update
    # Object to be edited already loaded into @ledger_object.
    if params[:preview]
      # Set the new values but don't save it.  So you can preview markdown text.
      @ledger_object = @ledger_object.append_version
      @ledger_object.assign_attributes(ledger_post_params)
      render('edit')
    elsif @ledger_object.update(ledger_post_params)
      flash[:success] = "#{@ledger_object.base_s} updated."
      redirect_to(ledger_post_path(@ledger_object))
    else # Failed to save, show error messages for field editing problems.
      render('edit')
    end
  end

  private

  def ledger_post_params
    params.require(:ledger_post).permit(:content)
  end
end
