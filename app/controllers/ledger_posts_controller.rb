# frozen_string_literal: true

class LedgerPostsController < LedgerBasesController
  def create
    @ledger_object = LedgerPost.new(
      creator_id: current_ledger_user.original_version_id)
    side_load_params
    super
  end

  # See parent class for generic edit() method.

  def index
    @ledger_objects = LedgerPost.where(deleted: false,
      is_latest_version: true).order(created_at: :desc)
      .paginate(page: params[:page])
  end

  ##
  # Create a reply to a given post.  It's sort of like a new post, but with
  # additional data specifying inherited groups and the link back to the post
  # being replied to.
  def reply
    original_post = LedgerPost.find(params[:id])
    @ledger_object = LedgerPost.new(
      creator_id: current_ledger_user.original_version_id,
      subject: original_post.subject,
      content: "Say something about " + original_post.content)

    @ledger_object.new_replytos << original_post.original_version

    home_link = LinkHomeGroup.find_by(
      parent_id: current_ledger_user.original_version_id)
    home_group = home_link.child if home_link
    @ledger_object.new_groups << home_group.original_version_id if home_group
    @ledger_object.new_groups << "Some other group number..."
    render('edit')
  end

  # See parent class for generic show() method.

  def update
    if @ledger_object.nil?
      @ledger_object = LedgerPost.new(
        creator_id: current_ledger_user.original_version_id)
    end
    side_load_params
    super
  end

  private

  def sanitised_params # Sanitise the inputs from the submitted form data.
    params.require(:ledger_post).permit(:content, :subject)
  end

  ##
  # For parameters that aren't exactly part of this @ledger_object, side load
  # them into instance variables specific to a LedgerPost.  They get used later
  # to create link objects when the main object is saved.  No, for several
  # reasons can't use nested attributes.
  def side_load_params
    if params && params[:groups]
      params[:groups].each do |key, value|
        value_int = value.to_i # Non-numbers show up as zero and get ignored.
        @ledger_object.new_groups << value_int if value_int > 0
      end
    end
p "Groups of #{@ledger_object} are: #{@ledger_object.new_groups}."
  end
end
