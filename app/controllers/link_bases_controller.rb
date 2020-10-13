# frozen_string_literal: true

class LinkBasesController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :index, :show]
  before_action :correct_user, only: [:destroy, :undelete, :edit, :update]

  def new
  end

  def create
  end

  def destroy
  end

  def index
    @link_objects = LinkBase.all.paginate(page: params[:page])
  end

  def show
    @link_object = LinkBase.find_by(id: params[:id]) # Can be nil.
  end

  def edit
  end

  def update
  end

  def undelete
  end

  private

  def correct_user
    @link_object = LinkBase.find(params[:id])
    unless @link_object&.creator_owner?(current_ledger_user)
      flash[:error] = "You're not the owner of that link object, " \
        "so you can't modify or delete it."
      redirect_to(root_url)
    end
  end
end
