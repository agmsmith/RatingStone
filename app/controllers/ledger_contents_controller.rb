# frozen_string_literal: true

class LedgerContentsController < LedgerBasesController
  # See parent class for generic create() method.

  def edit
    if @ledger_object
      @ledger_object.summary_of_changes = "Edited version of #{@ledger_object}."
    end
    super
  end

  def reply
    reply_or_quote(false)
  end

  def quote
    reply_or_quote(true)
  end

  # See parent class for generic show() method.

  def update
    if @ledger_object.nil? # Editing a new object, create in-memory record.
      @ledger_object = ledger_class_for_controller.new(
        creator_id: current_ledger_user.original_version_id,
        summary_of_changes: "New #{ledger_class_for_controller.name}.",
        rating_direction_self: "U",
      )
      # Make a default group link for the new object back to its creator.
      home_link = LinkHomeGroup.find_by(parent_id:
        current_ledger_user.original_version_id)
      home_group = home_link.child if home_link
      @ledger_object.new_groups << home_group.original_version_id if home_group
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
      @ledger_object.new_quotes << prior_post.original_version_id
    else
      @ledger_object.new_replytos << prior_post.original_version_id
    end

    # Add group links.  Same groups as the original post, plus user's group.
    LinkGroupContent.where(content_id: prior_post.original_version_id,
      deleted: false).each do |a_link|
      @ledger_object.new_groups << a_link.group_id
    end
    home_link = LinkHomeGroup.find_by(parent_id:
      current_ledger_user.original_version_id)
    home_group = home_link.child if home_link
    @ledger_object.new_groups << home_group.original_version_id if home_group
    render("edit")
  end

  ##
  # Note that :ledger_post_fields (the container of the fields of the post
  # being updated, and auxiliary arrays inside it) doesn't exist when throwing
  # up the form for a totally new post.
  def sanitised_params # Sanitise the main inputs from the submitted form data.
    return {} unless params.key?(:ledger_post_fields) # New form requested.

    params.require(:ledger_post_fields)
      .permit(:content, :subject, :summary_of_changes)
  end

  ##
  # For parameters that aren't exactly part of this new_object, side load
  # them into instance variables specific to a LedgerContent.
  def side_load_params(new_object)
    super
    if params && params[:new_groups].is_a?(Array)
      params[:new_groups].each do |x|
        group_id = x.to_i # Incomprehensible strings become 0.
        new_object.new_groups << group_id if group_id > 0
      end
    end
    new_object.new_groups << "Add a Group number here..."

    if params && params[:new_replytos].is_a?(Array)
      params[:new_replytos].each do |x|
        post_id = x.to_i # Incomprehensible strings become 0.
        new_object.new_replytos << post_id if post_id > 0
      end
    end
    new_object.new_replytos << "Add a Post number here..."

    if params && params[:new_quotes].is_a?(Array)
      params[:new_quotes].each do |x|
        post_id = x.to_i # Incomprehensible strings become 0.
        new_object.new_quotes << post_id if post_id > 0
      end
    end
    new_object.new_quotes << "Add a Post number here..."
  end

  # For information that isn't exactly part of this @ledger_object, side save
  # it into related records (create them) specific to the object class.  Returns
  # true if successful.  If it fails, return false with validation error
  # message strings appended to new_object, or just throw an exception.
  def side_save(new_object)
    return false unless super

    # Create some LinkGroupContent records to put the post into some groups.

    LedgerFullGroup.name # Force load of subclass so SQL searches for it too.
    new_object.new_groups.each do |group_item|
      group_id = group_item.to_i # Non-numbers show up as zero and get ignored.
      next if group_id <= 0

      a_group = LedgerSubgroup.find_by(id: group_id)
      if a_group
        link_group = LinkGroupContent.new(group_id: a_group.original_version_id,
          content_id: new_object.original_version_id,
          creator_id: current_ledger_user.original_version_id,
          rating_direction_parent: "U",
          rating_direction_child: "U")
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
      reply_id = reply_item.to_i # Non-numbers show up as zero and get ignored.
      next if reply_id <= 0

      prior_post = LedgerContent.find_by(id: reply_id)
      if prior_post
        link_post = LinkReply.new(prior_post_id: prior_post.original_version_id,
          reply_post_id: new_object.original_version_id,
          creator_id: current_ledger_user.original_version_id,
          rating_direction_parent: "U",
          rating_direction_child: "U")
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
      quote_id = quote_item.to_i # Non-numbers show up as zero and get ignored.
      next if quote_id <= 0

      prior_post = LedgerContent.find_by(id: quote_id)
      if prior_post
        link_post = LinkReply.new(reply_post_id: prior_post.original_version_id,
          prior_post_id: new_object.original_version_id,
          creator_id: current_ledger_user.original_version_id,
          rating_direction_parent: "U",
          rating_direction_child: "U")
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
