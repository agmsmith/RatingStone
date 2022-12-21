# frozen_string_literal: true

class LinkOpinionsController < LinkBasesController
  def create
    direction = "M" # Default direction if not specified for object and author.
    direction = "U" if params.key?(:U)
    direction = "M" if params.key?(:M)
    direction = "D" if params.key?(:D)

    @link_object = if params.key?(:opinion_about_link_id)
      unless LinkBase.find_by(id: params[:opinion_about_link_id])
        flash[:danger] = "When making an Opinion about a link, didn't find " \
          "a Link with ID ##{params[:opinion_about_link_id]}."
        return redirect_back(fallback_location: root_url)
      end
      LinkMetaOpinion.new(sanitised_params)
    else
      LinkOpinion.new(sanitised_params)
    end
    @link_object.creator_id = current_ledger_user.original_version_id

    # If the user didn't specify the points to spend, allocate a default amount,
    # with 3/4 to the object and 1/4 to the author.
    unless params.key?(:boost_author) || params.key?(:boost_object)
      amount = LinkBase::DEFAULT_SPEND_FOR_LINK *
        (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE) / 4.0
      @link_object.boost_author = amount
      @link_object.boost_object = 3.0 * amount
    end
    @link_object.rating_points_spent =
      (@link_object.boost_author + @link_object.boost_object) /
      (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE)

    @link_object.direction_author = direction unless params.key?(:direction_author)
    @link_object.direction_object = direction unless params.key?(:direction_object)

    unless @link_object.save
      error_message = "Failed to save your opinion."
      @link_object.errors.full_messages.each do |msg|
        error_message = error_message + " " + msg
      end
      flash[:danger] = error_message
      return redirect_back(fallback_location: root_url)
    end
    flash[:success] = "New #{@link_object.base_s} created."
    redirect_to(@link_object)
  end

  def index
    LinkMetaOpinion.name # FUTURE: Force load of subclasses of LinkOpinion here.
    @link_objects = LinkOpinion.where(deleted: false).order(created_at: :desc)
      .paginate(page: params[:page])
  end

  def show
    @link_object = LinkBase.find_by(id: params[:id]) # Can be nil.
  end

  private

  def sanitised_params # Sanitise the main inputs from the submitted form data.
    params.require(:opinion_about_object_id)
    params.require(:author_id)
    params.permit(:opinion_about_object_id, :author_id,
      :boost_author, :boost_object, :direction_author, :direction_object,
      :reason_why, :opinion_about_link_id)
  end
end
