class UsersController < ApplicationController
  
  def index
    @users = User.all.order(:login)
    @contributors = @users.select{|x| x.contributor}
    @others = @users.select{|x| !x.contributor}
  end

  def show
    @user = User.find_by_login(params[:id])
    @proposals = Proposal.all.sort_by{|x| x.number.to_i}.reverse
    @proposed, @proposals = @proposals.partition{|x| x.proposer == @user}
    @voted, @not_voted = @proposals.partition{|pr| @user.participating.where("last_vote IS NOT NULL").include? pr}
    @not_voted.reject!{|x| x.closed? }
  end

end
