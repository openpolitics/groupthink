# frozen_string_literal: true

#
# Displays lists of users and individual user profile pages.
#
class UsersController < ApplicationController
  before_action :get_user, except: [:index]
  before_action :authorise, only: [:edit, :update]

  def index
    @authors = User.where(author: true)
    @others = User.where(author: false)
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
    @has_cla = ENV["CLA_URL"].present?
  end

  def update
    if params.has_key?(:cla_accepted)
      accept_cla
    else
      @user.update!(user_params)
    end

    redirect_to edit_user_path(@user)
  end

private
  def get_user
    @user = User.find_by(login: params[:id])
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

  def accept_cla
    @user.update!(cla_accepted: true)

    @user.proposed.each do |pr|
      UpdateProposalJob.perform_later pr.number
    end
  end
end
