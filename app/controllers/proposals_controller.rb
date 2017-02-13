class ProposalsController < ApplicationController
  protect_from_forgery except: :webhook
  
  def index
    @open_proposals = Proposal.open.sort_by{|x| x.number.to_i}.reverse
    @closed_proposals = Proposal.closed.sort_by{|x| x.number.to_i}.reverse
  end
  
  def show
    @proposal = Proposal.find_by(number: params[:id])
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
      Proposal.find_by(number: issue['number']).try(:update_from_github!)
    end
  end

  def on_pull_request_opened(json)
    proposal = Proposal.create(number: json['number'])
  end
  
  def on_pull_request_closed(json)
    Proposal.find_by(number: json['number']).try(:close!)
  end
  
end
