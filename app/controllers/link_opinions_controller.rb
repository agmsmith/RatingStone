# frozen_string_literal: true

class LinkOpinionsController < LinkBasesController
  def create
    # First generally convert the params[] into a link record in @link_object.

    # For the one click opinion, we get a param of U or M or D.  For custom
    # opinions, they specify directions for each kind of thing separately.
    direction = "M" # Default direction if not specified for object and author.
    one_click_opinion = false
    "UMD".chars.each do |letter|
      if params.key?(letter)
        direction = letter
        one_click_opinion = true
      end
    end

    # Create the in-memory new link record of the appropriate type.
    id = params[:opinion_about_link_id].to_i # Maps nil to zero.
    @link_object = if id > 0
      LinkMetaOpinion.new(
        creator_id: current_ledger_user.original_version_id,
        opinion_about_link_id: id,
      )
    else
      LinkOpinion.new(creator_id: current_ledger_user.original_version_id)
    end

    @link_object.opinion_about_object_id = params[:opinion_about_object_id].to_i
    @link_object.boost_object = params[:boost_object].to_f
    dir_string = params[:direction_object].to_s.strip # Empty string if nil.
    @link_object.direction_object = if dir_string.empty?
      direction
    else
      dir_string
    end

    @link_object.author_id = params[:author_id].to_i
    @link_object.boost_author = params[:boost_author].to_f
    dir_string = params[:direction_author].to_s.strip
    @link_object.direction_author = if dir_string.empty?
      direction
    else
      dir_string
    end

    @link_object.reason_why = params[:reason_why].to_s.strip
    if @link_object.reason_why.empty?
      @link_object.reason_why = "User logged in from address " \
        "#{request.env["REMOTE_ADDR"]} custom edited this opinion and " \
        "didn't bother changing the reason."
    end

    # Second, validate the record id numbers and other information,
    # in particular make sure the original versions are being referenced.

    id = @link_object.opinion_about_object_id
    if LedgerBase.exists?(id)
      @link_object.opinion_about_object_id =
        LedgerBase.find(id).original_version_id
      id = @link_object.opinion_about_object_id
    end
    unless id > 0 && LedgerBase.exists?(id)
      @link_object.errors.add(
        :opinion_about_object_id,
        :record_does_not_exist,
        message: "needs a valid record number (not " \
          "#{params[:opinion_about_object_id]}), no " \
          "matter what; assign zero points if you don't care about it.",
      )
    end

    id = @link_object.author_id
    if LedgerBase.exists?(id)
      @link_object.author_id =
        LedgerBase.find(id).original_version_id
      id = @link_object.author_id
    end
    unless id > 0 && LedgerBase.exists?(id)
      @link_object.errors.add(
        :author_id,
        :record_does_not_exist,
        message: "needs a valid record number (not " \
          "#{params[:author_id]}), no " \
          "matter what; assign zero points if you don't care about it.",
      )
    end

    if @link_object.is_a?(LinkMetaOpinion)
      unless LinkBase.find_by(id: @link_object.opinion_about_link_id)
        @link_object.errors.add(
          :opinion_about_link_id,
          :record_does_not_exist,
          message: "needs a valid record number (not " \
            "#{params[:opinion_about_link_id]}).",
        )
      end
    end

    # If the user didn't specify the points to spend, allocate a default amount,
    # with 3/4 to the object and 1/4 to the author.
    if @link_object.boost_author <= 0.0 && @link_object.boost_object <= 0.0
      amount = LinkBase::DEFAULT_SPEND_FOR_LINK *
        (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE) / 4.0
      @link_object.boost_author = amount
      @link_object.boost_object = amount * 3.0
    end
    @link_object.rating_points_spent =
      (@link_object.boost_author + @link_object.boost_object) /
      (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE)
    if @link_object.boost_object < 0
      @link_object.errors.add(
        :boost_object,
        :negative_points_spent,
        message: "don't spend negative points " \
          "(not #{params[:boost_object]}).",
      )
    end
    if @link_object.boost_author < 0
      @link_object.errors.add(
        :boost_author,
        :negative_points_spent,
        message: "don't spend negative points " \
          "(not #{params[:boost_author]}).",
      )
    end
    if @link_object.rating_points_spent <= 0.0
      @link_object.errors.add(
        :rating_points_spent,
        :no_points_spent,
        message: "need to spend a positive total number of points, " \
          "#{@link_object.rating_points_spent} is too low.",
      )
    end

    if @link_object.errors.empty?
      # No errors so far, so run the standard validations to add more errors.
      # Note that running valid? clears out the previous errors.
      @link_object.valid?
    end

    if !@link_object.errors.empty? ||
        params[:preview] ||
        (one_click_opinion && current_user.preview_opinion)
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
    render("show")
  end

  def index
    LinkMetaOpinion.name # FUTURE: Force load of subclasses of LinkOpinion here.
    @pagy, @link_objects = pagy(LinkOpinion.where(deleted: false).order(created_at: :desc))
  end

  def new
    create
  end

  def show
    @link_object = LinkBase.find_by(id: params[:id]) # Can be nil.
  end
end
