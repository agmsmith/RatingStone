# frozen_string_literal: true

class LedgerContentsController < LedgerBasesController
  # See parent class for generic create() method.

  def edit
    if @ledger_object
      @ledger_object.summary_of_changes = "Edited version of #{@ledger_object}."
    end
    super
  end

  def quote
    reply_or_quote(true)
  end

  def reply
    reply_or_quote(false)
  end

  # See parent class for generic show() method.

  ##
  # Handle both changes after editing, edit preview, and creating new objects.
  def update
    if @ledger_object.nil? # Editing a new object, create in-memory record.
      @ledger_object = ledger_class_for_controller.new(
        creator_id: current_ledger_user.original_version_id,
        summary_of_changes: "New #{ledger_class_for_controller.name}.",
        rating_direction_self: "U",
      )
      unless params.key?(:ledger_post_fields) # First time, no form fields yet.
        # Make a default group link for the new object back to its creator.
        home_link = LinkHomeGroup.find_by(parent_id:
          current_ledger_user.original_version_id)
        home_group = home_link.child if home_link
        if home_group
          @ledger_object.new_groups << { ID: home_group.original_version_id,
            UMD: "U", Points: LinkBase::DEFAULT_SPEND_FOR_LINK, }
        end
      end
    end
    super
  end

  private

  ##
  # Returns the Ledger class that's appropriate for this controller to handle.
  # Can be used for creating new objects of the appropriate class.
  def ledger_class_for_controller
    # FUTURE: Force load subclasses of LedgerContent (lazy loading sometimes
    # misses them) so ActiveRecord searches for them too when looking for
    # objects of LedgerContent class.
    LedgerPost.name
    LedgerContent
  end

  ##
  # Create a reply to a given content item.  It's sort of like a new post, but
  # with additional data specifying inherited groups and the link back to the
  # post being replied to.  Set it up and let the user edit it.
  def reply_or_quote(quoting)
    # FUTURE: Force load future subclasses of LedgerContent here.
    LedgerPost.name
    prior_post = LedgerContent.find(params[:id]) # Can be any version of post.
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
      @ledger_object.new_quotes << { ID: prior_post.original_version_id,
        UMD: "U", Points: LinkBase::DEFAULT_SPEND_FOR_LINK, }
    else
      @ledger_object.new_replytos << { ID: prior_post.original_version_id,
        UMD: "U", Points: LinkBase::DEFAULT_SPEND_FOR_LINK, }
    end

    # Add group links.  Same groups as the original post.
    LinkGroupContent.where(content_id: prior_post.original_version_id,
      deleted: false).each do |a_link|
      @ledger_object.new_groups << { ID: a_link.group_id, UMD: "U",
        Points: LinkBase::DEFAULT_SPEND_FOR_LINK, }
    end
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
  # ID, UMD, Points), rejecting ones with ID <= 0 or no Points, and only
  # keeping the first one where there are duplicate IDs.
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
      next unless array_umd[index] && array_points[index] &&
        array_points[index] > 0.0

      tuple_array <<
        { ID: id, UMD: array_umd[index], Points: array_points[index] }
      known_ids << id
    end
    tuple_array
  end

  ##
  # For parameters that aren't exactly part of this new_object, side load
  # them into instance variables specific to a LedgerContent.
  def side_load_params(new_object)
    super
    if params && params[:new_groups]
      new_object.new_groups = form_to_tuples(params[:new_groups])
    end
    new_object.new_groups <<
      { ID: "Add a Group number here...", UMD: "U", Points: 0.0 }

    if params && params[:new_replytos]
      new_object.new_replytos = form_to_tuples(params[:new_replytos])
    end
    new_object.new_replytos <<
      { ID: "Add a reply Post number here...", UMD: "U", Points: 0.0 }

    if params && params[:new_quotes]
      new_object.new_quotes = form_to_tuples(params[:new_quotes])
    end
    new_object.new_quotes <<
      { ID: "Add a quoted Post number here...", UMD: "U", Points: 0.0 }
  end

  # For information that isn't exactly part of this @ledger_object, side save
  # it into related records (create them) specific to the object class.  Returns
  # true if successful.  If it fails, return false with validation error
  # message strings appended to new_object, or just throw an exception.
  def side_save(new_object)
    return false unless super

    # FUTURE: Force load future subclasses of LedgerContent here.
    LedgerPost.name
    # FUTURE: Force load future subclasses of LedgerSubgroup here.
    LedgerFullGroup.name

    # Create some LinkGroupContent records to put the post into some groups.

    new_object.new_groups.each do |group_item|
      group_id = group_item[:ID].to_i # So ID filler text becomes zero.
      next if group_id <= 0

      a_group = LedgerSubgroup.find_by(id: group_id)
      if a_group
        link_group = LinkGroupContent.new(group_id: a_group.original_version_id,
          content_id: new_object.original_version_id,
          creator_id: current_ledger_user.original_version_id,
          rating_points_spent: group_item[:Points],
          rating_points_boost_parent: group_item[:Points] *
            (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE),
          rating_direction_parent: group_item[:UMD])
        unless link_group.save
          new_object.errors.add(:base,
            "Failed to make link to Group #{group_id}.")
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
      next if reply_id <= 0

      prior_post = LedgerContent.find_by(id: reply_id)
      if prior_post
        link_post = LinkReply.new(prior_post_id: prior_post.original_version_id,
          reply_post_id: new_object.original_version_id,
          creator_id: current_ledger_user.original_version_id,
          rating_points_spent: reply_item[:Points],
          rating_points_boost_parent: reply_item[:Points] *
            (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE),
          rating_direction_parent: reply_item[:UMD])
        unless link_post.save
          new_object.errors.add(:base,
            "Failed to make link back to original #{prior_post} for " \
              "reply #{new_object}.")
          link_post.errors.each do |error_key, error_value|
            new_object.errors.add(error_key, error_value)
          end
          return false
        end
      else
        new_object.errors.add(:base,
          "Original post #{reply_item} does not exist or is wrong type.")
        return false
      end
    end

    # Create some LinkReply records to make other posts a reply to this one,
    # a quote in effect.

    new_object.new_quotes.each do |quote_item|
      quote_id = quote_item[:ID].to_i
      next if quote_id <= 0

      prior_post = LedgerContent.find_by(id: quote_id)
      if prior_post
        link_post = LinkReply.new(reply_post_id: prior_post.original_version_id,
          prior_post_id: new_object.original_version_id,
          creator_id: current_ledger_user.original_version_id,
          rating_points_spent: quote_item[:Points],
          rating_points_boost_child: quote_item[:Points] *
            (1.0 - LinkBase::LINK_TRANSACTION_FEE_RATE),
          rating_direction_child: quote_item[:UMD])
        unless link_post.save
          new_object.errors.add(:base,
            "Failed to make link back to original #{new_object} for " \
              "reply #{prior_post}.")
          link_post.errors.each do |error_key, error_value|
            new_object.errors.add(error_key, error_value)
          end
          return false
        end
      else
        new_object.errors.add(:base,
          "Original post #{quote_item} does not exist or is wrong type.")
        return false
      end
    end

    true
  end
end
