# frozen_string_literal: true

class LedgerPostsController < LedgerBasesController
  # See parent class for generic create() method.

  def index
    @ledger_objects = LedgerPost.where(deleted: false,
      is_latest_version: true).order(created_at: :desc)
      .paginate(page: params[:page])
  end

  ##
  # Create a reply to a given post.  It's sort of like a new post, but with
  # additional data specifying inherited groups and the link back to the post
  # being replied to.  Set it up and let the user edit it.
  def reply
    original_post = LedgerPost.find(params[:id])
    @ledger_object = LedgerPost.new(
      creator_id: current_ledger_user.original_version_id,
      subject: original_post.subject,
      content: "Say something about " + original_post.content
    )

    # Add reply links.  Just start by replying to the original message.
    @ledger_object.new_replytos << original_post.original_version_id

    # Add group links.  Same groups as the original post, plus user's group.
    original_group_links = LinkGroupContent.where(
      content_id: original_post.original_version_id, deleted: false
    )
    original_group_links.each do |a_link|
      @ledger_object.new_groups << a_link.group_id
    end
    home_link = LinkHomeGroup.find_by(
      parent_id: current_ledger_user.original_version_id
    )
    home_group = home_link.child if home_link
    @ledger_object.new_groups << home_group.original_version_id if home_group

    side_load_params(@ledger_object) # Mostly to get the "Add a new..." entries.
    render('edit')
  end

  # See parent class for generic show() method.

  def update
    if @ledger_object.nil?
      @ledger_object = LedgerPost.new(
        creator_id: current_ledger_user.original_version_id
      )
    end
    super
  end

  private

  def sanitised_params # Sanitise the main inputs from the submitted form data.
    params.require(:ledger_post).permit(:content, :subject, :summary_of_changes)
  end

  ##
  # For parameters that aren't exactly part of this new_object, side load
  # them into instance variables specific to a LedgerPost.
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
  end

  # For information that isn't exactly part of this @ledger_object, side save
  # it into related records specific to the object class.
  # TODO: move this to the model class, makes more sense there, if we can get transactions to work.
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
          creator_id: current_ledger_user.original_version_id)
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
      original_post = LedgerPost.find_by(id: reply_id)
      if original_post
        link_post = LinkReply.new(
          original_post_id: original_post.original_version_id,
          reply_post_id: new_object.original_version_id,
          creator_id: current_ledger_user.original_version_id
        )
        unless link_post.save
          new_object.errors.add(:base,
            "Failed to make link back to original #{original_post} for " \
            "reply #{new_object}.")
          link_post.errors.each do |error_key, error_value|
            new_object.errors.add(error_key, error_value)
          end
          return false
        end
      else
        new_object.errors.add(:base,
          "Original post #{reply_item} does not exist.")
        return false
      end
    end

    true
  end
end
