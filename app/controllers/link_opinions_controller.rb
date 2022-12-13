# frozen_string_literal: true

class LinkOpinionsController < LinkBasesController
  def create
  end

  def index
    @link_objects = LinkOpinion.where(deleted: false).order(created_at: :desc)
      .paginate(page: params[:page])
  end

  def show
    @link_object = LinkBase.find_by(id: params[:id]) # Can be nil.
  end

  private
end
