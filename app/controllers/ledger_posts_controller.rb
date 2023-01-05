# frozen_string_literal: true

class LedgerPostsController < LedgerBasesController
  # See parent classes for generic create, edit, index and other methods.

  ##
  # Show a tree of all quotes of a specified post.
  def ancestors
    @ledger_post = LedgerPost.find(params[:id])
    @ledger_objects = LedgerPost.tree_of_quotes(
      id: @ledger_post.original_version_id)
      .paginate(page: params[:page])
  end

  ##
  # Show a tree of all replies to a specified post.
  def descendants
    @ledger_post = LedgerPost.find(params[:id])
    @ledger_objects = LedgerPost.tree_of_replies(
      id: @ledger_post.original_version_id)
      .paginate(page: params[:page])
  end

  def edit
    if @ledger_object
      @ledger_object.summary_of_changes = "Edited version of #{@ledger_object}."
    end
    super
  end

  ##
  # Make a new quote referencing the specified post.
  def quote
    quote_or_reply(true)
  end

  ##
  # List all quotes of a specified post.
  def quotes
    if params[:id]
      @ledger_object = ledger_class_for_controller.find_by(id: params[:id])
    end
    unless @ledger_object
      flash[:danger] = "Can't find object ##{params[:id]} to show quotes."
      return redirect_back(fallback_location: root_url)
    end
    @ledger_objects = @ledger_object.quotes_good
      .paginate(page: params[:page])
  end

  ##
  # Make a new reply referencing the specified post.
  def reply
    quote_or_reply(false)
  end

  ##
  # List all replies to a specified post.
  def replies
    if params[:id]
      @ledger_object = ledger_class_for_controller.find_by(id: params[:id])
    end
    unless @ledger_object
      flash[:danger] = "Can't find object ##{params[:id]} to show replies."
      return redirect_back(fallback_location: root_url)
    end
    @ledger_objects = @ledger_object.replies_good
      .paginate(page: params[:page])
  end

  # See parent class for generic show() method.

  ##
  # Handle changes after editing, edit preview, and creating new objects.
  def update
    if @ledger_object.nil? # Editing a new object, create in-memory record.
      @ledger_object = ledger_class_for_controller.new(
        creator_id: current_ledger_user.original_version_id,
        summary_of_changes: "New #{ledger_class_for_controller.name}.",
        rating_direction_self: "U",
      )
    end
    unless params.key?(:ledger_post_fields) && # First time, no group field yet.
        params[:ledger_post_fields].key?(:new_groups)
      # Make a home group link for the new object back to its creator's group.
      home_group = current_ledger_user.home_group
      if home_group
        @ledger_object.new_groups << {
          ID: home_group.original_version_id,
          UMD: "U",
          Points: LinkBase::DEFAULT_SPEND_FOR_LINK,
        }
      end
    end
    super
  end

  private

  ##
  # Appends extra dummy spots to the side load attributes of a given object,
  # for new groups, replies and quotes.  These show up in the form as extra
  # fields that let the user fill in the dummy info (has zero points and
  # zero ID so will get ignored unless changed) to add new groups, replies
  # and quotes.
  def append_dummy_side_load_attributes(new_object)
    new_object.new_groups <<
      { ID: "Group #?", UMD: "U", Points: "Points?" }
    new_object.new_replytos <<
      { ID: "Reply Post #?", UMD: "U", Points: "Points?" }
    new_object.new_quotes <<
      { ID: "Quoted Post #?", UMD: "U", Points: "Points?" }
  end

  ##
  # Returns the Ledger class that's appropriate for this controller to handle.
  # Can be used for creating new objects of the appropriate class.
  # FUTURE: Should preload subclasses here since this is often used just before
  # a database find_by.
  def ledger_class_for_controller
    LedgerPost
  end

  ##
  # Start editing a reply or quote to a given content item.  It's sort of like
  # a new post, but with additional data specifying inherited groups and the
  # link back to the post being replied to.  Set it up and let the user edit it.
  def quote_or_reply(quoting)
    prior_post = LedgerPost.find_by(id: params[:id]) # Can be any version of post.
    unless prior_post
      flash[:danger] = "Can't find object ##{params[:id]} to show " \
        "#{quoting ? "quotes" : "replies"}."
      return redirect_back(fallback_location: root_url)
    end
    new_subject = prior_post.subject
    prefix = "#{quoting ? "Qt:" : "Re:"} "
    new_subject = prefix + new_subject unless new_subject.start_with?(prefix)
    @ledger_object = ledger_class_for_controller.new(
      creator_id: current_ledger_user.original_version_id,
      subject: new_subject,
      content: "Say something about " + prior_post.content,
      summary_of_changes: "#{quoting ? "Quote of" : "Reply to"} #{prior_post}.",
    )

    # Add reply/quote links.  Just start by replying to the original message.
    if quoting
      @ledger_object.new_quotes << {
        ID: prior_post.original_version_id,
        UMD: "U",
        Points: LinkBase::DEFAULT_SPEND_FOR_LINK,
      }
    else
      @ledger_object.new_replytos << {
        ID: prior_post.original_version_id,
        UMD: "U",
        Points: LinkBase::DEFAULT_SPEND_FOR_LINK,
      }
    end

    # Add group links.  Same groups as the original post.
    LinkGroupContent.where(
      content_id: prior_post.original_version_id,
      deleted: false,
    ).each do |a_link|
      @ledger_object.new_groups << {
        ID: a_link.group_id,
        UMD: "U",
        Points: LinkBase::DEFAULT_SPEND_FOR_LINK,
      }
    end
    append_dummy_side_load_attributes(@ledger_object)
    render("edit")
  end

  ##
  # Note that :ledger_post_fields (the container of the fields of the post
  # being updated, and auxiliary arrays inside it) doesn't exist when throwing
  # up the form for a totally new post.
  def sanitised_params # Sanitise the main inputs from the submitted form data.
    return {} unless params.key?(:ledger_post_fields) # New form was requested.

    params.require(:ledger_post_fields)
      .permit(:content, :subject, :summary_of_changes)
  end

  ##
  # Convert form parameters into an array of tuples.  Input is a hash of form
  # parameters, keys being (index digit + "_" + purpose code (ID, UMD, Points)),
  # value being the user's input.  Output is an array of tuples (a Hash with
  # ID, UMD, Points), rejecting ones with ID <= 0, and only keeping the first
  # one where there are duplicate IDs.  Unfortunately wasn't able to get the
  # automatic conversion working for fields with "[]" in the name into arrays.
  def form_to_tuples(form_params)
    array_id = [] # Store the input data in separate arrays.
    array_umd = []
    array_points = []

    # First step - just read in the form info and store in the data arrays.

    form_params.each_pair do |key, value|
      next unless /^[0-9]_.*$/ =~ key # Key is single digit "9_something"

      key_index = key.to_i
      if /^[0-9]_ID$/ =~ key
        array_id[key_index] = value.to_i # Incomprehensible strings become 0.
      elsif /^[0-9]_UMD$/ =~ key && /^[UMD]$/ =~ value
        array_umd[key_index] = value
      elsif /^[0-9]_Points$/ =~ key
        array_points[key_index] = value.to_f
      end
    end

    # Second step - append just the valid (all elements present, not a
    # duplicate ID) data items to the output array.

    known_ids = Set.new # For finding duplicates.
    tuple_array = []
    array_id.each_with_index do |id, index|
      next if id <= 0 || known_ids.include?(id)
      next unless array_umd[index] && array_points[index]

      tuple_array <<
        { ID: id, UMD: array_umd[index], Points: array_points[index] }
      known_ids << id
    end
    tuple_array
  end

  ##
  # For parameters that aren't exactly part of this new_object, side load
  # them into instance variables specific to a LedgerPost.
  def side_load_params(new_object)
    super
    if params && params[:new_groups]
      new_object.new_groups = form_to_tuples(params[:new_groups])
    end
    if params && params[:new_replytos]
      new_object.new_replytos = form_to_tuples(params[:new_replytos])
    end
    if params && params[:new_quotes]
      new_object.new_quotes = form_to_tuples(params[:new_quotes])
    end
    append_dummy_side_load_attributes(new_object)
  end

  # For information that isn't exactly part of this @ledger_object, side save
  # it into related records (create them) specific to the object class.  Returns
  # true if successful.  If it fails, return false with validation error
  # message strings appended to new_object, or just throw an exception.
  def side_save(new_object)
    return false unless super

    # FUTURE: Force load future subclasses of LedgerSubgroup here.
    LedgerFullGroup.name

    # Create some LinkGroupContent records to put the post into some groups.

    new_object.new_groups.each do |group_item|
      group_id = group_item[:ID].to_i # So ID filler text becomes zero.
      points = group_item[:Points].to_f
      next if group_id <= 0 || points <= 0.0

      a_group = LedgerSubgroup.find_by(id: group_id)
      if a_group
        link_group = LinkGroupContent.new(
          group_id: a_group.original_version_id,
          content_id: new_object.original_version_id,
          creator_id: current_ledger_user.original_version_id,
          rating_points_spent: points,
          rating_points_boost_parent: points *
                      (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE),
          rating_direction_parent: group_item[:UMD],
        )
        unless link_group.save
          new_object.errors.add(
            :base,
            "Failed to make link to Group #{group_id}.",
          )
          link_group.errors.each do |error_key, error_value|
            new_object.errors.add(error_key, error_value)
          end
          return false
        end
      else
        new_object.errors.add(:base, "Group #{group_id} does not exist.")
        return false
      end
    end

    # Create some LinkReply records to make the post a reply of other posts.

    new_object.new_replytos.each do |reply_item|
      reply_id = reply_item[:ID].to_i
      points = reply_item[:Points].to_f
      next if reply_id <= 0 || points <= 0.0

      prior_post = LedgerPost.find_by(id: reply_id)
      if prior_post
        link_post = LinkReply.new(
          prior_post_id: prior_post.original_version_id,
          reply_post_id: new_object.original_version_id,
          creator_id: current_ledger_user.original_version_id,
          rating_points_spent: points,
          rating_points_boost_parent: points *
                      (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE),
          rating_direction_parent: reply_item[:UMD],
        )
        unless link_post.save
          new_object.errors.add(
            :base,
            "Failed to make link back to original #{prior_post} for " \
              "reply #{new_object}.",
          )
          link_post.errors.each do |error_key, error_value|
            new_object.errors.add(error_key, error_value)
          end
          return false
        end
      else
        new_object.errors.add(
          :base,
          "Original post #{reply_item} does not exist or is wrong type.",
        )
        return false
      end
    end

    # Create some LinkReply records to make other posts a reply to this one,
    # a quote in effect.

    new_object.new_quotes.each do |quote_item|
      quote_id = quote_item[:ID].to_i
      points = quote_item[:Points].to_f
      next if quote_id <= 0 || points <= 0

      prior_post = LedgerPost.find_by(id: quote_id)
      if prior_post
        link_post = LinkReply.new(
          reply_post_id: prior_post.original_version_id,
          prior_post_id: new_object.original_version_id,
          creator_id: current_ledger_user.original_version_id,
          rating_points_spent: points,
          rating_points_boost_child: points *
                      (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE),
          rating_direction_child: quote_item[:UMD],
        )
        unless link_post.save
          new_object.errors.add(
            :base,
            "Failed to make link back to original #{new_object} for " \
              "reply #{prior_post}.",
          )
          link_post.errors.each do |error_key, error_value|
            new_object.errors.add(error_key, error_value)
          end
          return false
        end
      else
        new_object.errors.add(
          :base,
          "Original post #{quote_item} does not exist or is wrong type.",
        )
        return false
      end
    end

    true
  end
end
