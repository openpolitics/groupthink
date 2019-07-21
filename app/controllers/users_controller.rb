# frozen_string_literal: true

#
# Displays lists of users and individual user profile pages.
#
class UsersController < ApplicationController
  before_action :get_user, except: [:index]
  before_action :authorise, only: [:edit, :update]

  def index
    @contributors = User.where(contributor: true)
    @others = User.where(contributor: false)
  end

  def show
    # Get proposed list
    @proposed = @user.proposed
    @proposed_count = @proposed.count
    @proposed = @proposed.page params[:proposed_page]
    # Get voted list
    @voted = @user.voted_on
    @voted_count = @voted.count
    @voted = @voted.page params[:voted_page]
    # Get list not yet voted on
    @not_voted = @user.not_voted_on
  end

  def edit
  end

  def update
    @user.update_attributes!(user_params)
    redirect_to edit_user_path(@user)
  end

private
  def get_user
    @user = User.find_by_login(params[:id])
    raise ActiveRecord::RecordNotFound if @user.nil?
  end

  def authorise
    if @user != current_user
      redirect_to @user
    end
  end

  def user_params
    params.require(:user).permit(:email, :notify_new)
  end
end
