# frozen_string_literal: true

class LedgerPostsController < LedgerObjectsController
  def create
    @ledger_object = LedgerPost.new(
      creator_id: current_ledger_user.original_version_id)
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

    @ledger_object.link_ups.build(type: 'LinkReply',
      creator_id: current_ledger_user.original_version_id,
      parent: original_post.original_version, child: @ledger_object)

    home_link = LinkHomeGroup.find_by(
      parent_id: current_ledger_user.original_version_id)
    home_group = home_link.child if home_link
    if home_group
      @ledger_object.link_ups.build(type: 'LinkGroupContent',
        creator_id: current_ledger_user.original_version_id,
        parent: home_group, child: @ledger_object)
    end

    render('edit')
  end

  # See parent class for generic show() method.

  def update
    if @ledger_object.nil?
      @ledger_object = LedgerPost.new(
        creator_id: current_ledger_user.original_version_id)
    end
    super
  end

  private

  def sanitised_params # Sanitise the inputs from the submitted form data.
puts "Params: #{params}" # bleeble
    combined_params = params.require(:ledger_post).permit(:content, :subject,
      link_ups_attributes: [:id, :parent_id, :type],
      link_downs_attributes: [:id, :child_id, :type])
    up_params = params.require(:ledger_post).require(:link_ups_attributes)
      .select do |x, y|
        puts "X is #{x}, Y is #{y}"
        y[:id].nil?
      end
# Bleeble - inject creator into new record link ups etc.
puts "Up: #{up_params}" # bleeble
puts "Returned: #{combined_params}" # bleeble
    combined_params
  end
end
