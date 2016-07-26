class ProposalsController < ApplicationController

  def index
    @open_proposals = Proposal.open.sort_by{|x| x.number.to_i}.reverse
    @closed_proposals = Proposal.closed.sort_by{|x| x.number.to_i}.reverse
  end
  
  def show
    @proposal = Proposal.find_by(number: params[:id])
  end
  
  def update
    @proposal = Proposal.find_by(number: params[:number])
    @proposal.update_from_github!
    redirect "/#{params[:number]}"
  end

end
