class ProposalsController < ApplicationController

  def index
    @open_proposals = Proposal.open.sort_by{|x| x.number.to_i}.reverse
    @closed_proposals = Proposal.closed.sort_by{|x| x.number.to_i}.reverse
  end
  
  def show
    @proposal = Proposal.find_by(number: params[:id])
  end
  
  def update
    @proposal = Proposal.find_by(number: params[:id])
    @proposal.update_from_github!
    redirect "/#{params[:id]}"
  end
  
  def update_all
    User.update_all_from_github!
    Proposal.recreate_all_from_github!
    head 200
  end

  def webhook
    case request.env['HTTP_X_GITHUB_EVENT']
    when "issue_comment"
      on_issue_comment(JSON.parse(params[:payload]))
      head 200
    when "pull_request"
      on_pull_request(JSON.parse(params[:payload]))
      head 200
    else
      head 400
    end
  end
  
  private
  
  def on_issue_comment(json)
    case json['action']
    when 'created'
      on_issue_comment_created(json)
    end
  end
  
  def on_pull_request(json)
    case json['action']
    when 'opened'
      on_pull_request_opened(json)
    when 'closed'
      on_pull_request_closed(json)
    end
  end

  def on_issue_comment_created(json)
    issue = json['issue']
    if issue['state'] == 'open' && issue['pull_request']
      Proposal.create_from_github!(issue['number'])
    end
  end

  def on_pull_request_opened(json)
    Proposal.create_from_github!(json['number'])
  end
  
  def on_pull_request_closed(json)
    Proposal.find_or_create_by(number: json['number']).try(:close!)
  end
  
end
