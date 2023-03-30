# frozen_string_literal: true

class LinkOpinionsController < LinkBasesController
  def create
    direction = "M" # Default direction if not specified for object and author.
    direction = "U" if params.key?(:U)
    direction = "M" if params.key?(:M)
    direction = "D" if params.key?(:D)

    @link_object = if params.key?(:opinion_about_link_id)
      LinkMetaOpinion.new(
        creator_id: current_ledger_user.original_version_id,
        opinion_about_object_id: params[:opinion_about_object_id].to_i,
        opinion_about_link_id: params[:opinion_about_link_id].to_i,
      )
    else
      LinkOpinion.new(
        creator_id: current_ledger_user.original_version_id,
        opinion_about_object_id: params[:opinion_about_object_id].to_i,
      )
    end
    if params[:author_id]
      @link_object.author_id = params[:author_id].to_i
    end
    if params[:boost_author]
      @link_object.boost_author = params[:boost_author].to_f
    end
    if params[:boost_object]
      @link_object.boost_object = params[:boost_object].to_f
    end
    if params[:direction_author]
      @link_object.direction_author = params[:direction_author]
    end
    if params[:direction_object]
      @link_object.direction_object = params[:direction_object]
    end
    @link_object.reason_why = if params[:reason_why]
      params[:reason_why]
    else
      @link_object.reason_why = "User logged in from address " \
        "#{request.env["REMOTE_ADDR"]}."
    end

    # Make sure the original version is the one being referenced.
    if @link_object.author_id
      @link_object.author_id = @link_object.author.original_version_id
    end
    @link_object.opinion_about_object_id =
      @link_object.opinion_about_object.original_version_id

    # If the user didn't specify the points to spend, allocate a default amount,
    # with 3/4 to the object and 1/4 to the author.
    unless params.key?(:boost_author) || params.key?(:boost_object)
      amount = LinkBase::DEFAULT_SPEND_FOR_LINK *
        (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE) / 4.0
      @link_object.boost_author = amount
      @link_object.boost_object = amount * 3.0
    end
    @link_object.rating_points_spent =
      (@link_object.boost_author + @link_object.boost_object) /
      (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE)

    @link_object.direction_author = direction unless params.key?(:direction_author)
    @link_object.direction_object = direction unless params.key?(:direction_object)

    if @link_object.is_a?(LinkMetaOpinion)
      unless LinkBase.find_by(id: params[:opinion_about_link_id])
        flash[:danger] = "When making an Opinion about a link, didn't find " \
          "a Link with ID ##{params[:opinion_about_link_id]}."
        return render("create")
      end
    end

    if params[:preview]
      return render("create")
    end

    unless @link_object.save
      error_message = "Failed to save your opinion."
      @link_object.errors.full_messages.each do |msg|
        error_message = error_message + " " + msg
      end
      flash[:danger] = error_message
      return render("create")
    end
    flash[:success] = "New #{@link_object.base_s} created."
    redirect_to(@link_object)
  end

  def index
    LinkMetaOpinion.name # FUTURE: Force load of subclasses of LinkOpinion here.
    @link_objects = LinkOpinion.where(deleted: false).order(created_at: :desc)
      .paginate(page: params[:page])
  end

  def new
    create
  end

  def show
    @link_object = LinkBase.find_by(id: params[:id]) # Can be nil.
  end
end
