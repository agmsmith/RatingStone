# frozen_string_literal: true

class LedgerObjectsController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :index, :show]
  before_action :correct_user, only: [:destroy, :undelete, :edit, :update]

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
    @ledger_object = LedgerBase.find(params[:id])
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
end
