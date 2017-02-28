class UsersController < ApplicationController

  before_filter :get_user, except: [:index]
  before_action :authorise, only: [:edit, :update]
  
  def index
    @users = User.all.order(:login)
    @contributors = @users.select{|x| x.contributor}
    @others = @users.select{|x| !x.contributor}
  end

  def show
    @proposals = Proposal.all.order(number: :desc)
    @proposed, @proposals = @proposals.partition{|x| x.proposer == @user}
    @voted, @not_voted = @proposals.partition{|pr| @user.participating.where("last_vote IS NOT NULL").include? pr}
    @not_voted.reject!{|x| x.closed? }
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
