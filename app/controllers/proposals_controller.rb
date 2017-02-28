class ProposalsController < ApplicationController
  protect_from_forgery except: :webhook
  before_filter :get_proposal, except: [:index, :webhook]
  
  def index
    @open_proposals = Proposal.open.sort_by{|x| x.number.to_i}.reverse
    @closed_proposals = Proposal.closed.sort_by{|x| x.number.to_i}.reverse
  end
  
  def show
    # Can the current user vote?
    @can_vote = current_user.try(:contributor) && current_user != @proposal.proposer
    # Generate unified activity list
    @activity = []
    # Add commits
    @activity.concat(@proposal.commits.map{|commit|
      ['diff', {
        sha: commit[:sha],
        user: User.find_by_login(commit[:commit][:author][:name]),
        proposal: @proposal, 
        original_url: @proposal.url,
        time: commit[:commit][:author][:date]
      }]
    })
    # Add original description
    @activity << ['comment', {
      body: @proposal.github_pr.body,
      user: @proposal.proposer, 
      proposal: @proposal, 
      original_url: @proposal.url,
      time: @proposal.github_pr.created_at
    }] if @proposal.github_pr.body
    # Add comments
    comments = Octokit.issue_comments(ENV['GITHUB_REPO'], @proposal.number)
    @activity.concat(comments.map{|comment|
      next if comment.body =~ /votebot instructions/
      ['comment', {
        body: comment.body, 
        user: User.find_by_login(comment.user.login), 
        proposal: @proposal, 
        original_url: comment.html_url,
        time: comment.created_at
      }]
    })
    # Remove any empty elements
    @activity.compact!
    # Sort by time
    @activity.sort_by! { |a| a[1][:time] }
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
  
  def comment
    github = Octokit::Client.new(:access_token => session[:github_token])
    comment = params[:comment]
    case params[:vote]
      when "yes"
        comment += "\n\nVote: ✅"
      when "no"
        comment += "\n\nVote: ❎"
      when "block"
        comment += "\n\nVote: 🚫"
    end
    github.add_comment(ENV['GITHUB_REPO'], @proposal.number, comment)
    redirect_to @proposal
  end
  
  private
  
  def get_proposal
    @proposal = Proposal.find_by_number(params[:id])
  end
  
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
