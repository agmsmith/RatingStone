# frozen_string_literal: true

class LedgerObjectsController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :index]
  before_action :correct_user, only: [:destroy, :undelete, :edit, :update]
  before_action :reader_user, only: [:show]

  def new
  end

  def create
  end

  def destroy
  end

  def index
    @ledger_objects = LedgerBase.all.paginate(page: params[:page])
  end

  def show
    # @ledger_object has already been set by before_actions.
  end

  def edit
  end

  def update
  end

  def undelete
  end

  private

  def correct_user
    @ledger_object = LedgerBase.find(params[:id])
    unless @ledger_object.creator_owner?(current_ledger_user)
      flash[:error] = "You're not the owner of that ledger object, " \
        "so you can't modify or delete it."
      redirect_to(root_url)
    end
  end

  def reader_user
    @ledger_object = LedgerBase.find(params[:id])
    # Can only be a reader if this is a group or a post/content.
    unless @ledger_object.role_test?(current_ledger_user, LinkRole::READER)
      flash[:error] = "You don't have permission to read that ledger object, " \
        "so you can't see it."
      redirect_to(root_url)
    end
  end
end
