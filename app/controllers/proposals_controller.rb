# frozen_string_literal: true

#
# Shows proposal pages and handles webhook updates from GitHub.
#
class ProposalsController < ApplicationController
  protect_from_forgery except: :webhook
  before_action :get_proposal, except: [:index, :webhook]
  before_action :authenticate_user!, only: [:comment]

  def index
    @open_proposals = Proposal.open
    @closed_proposals = Proposal.closed.page params[:page]
  end

  def show
    @is_author = current_user == @proposal.proposer
    # Can the current user vote?
    @can_vote = current_user.try(:voter) && !@is_author
    # Get activity list
    presenter = ProposalPresenter.new(@proposal)
    @activity = presenter.activity_log
  end

  def webhook
    case request.env["HTTP_X_GITHUB_EVENT"]
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
    github = Octokit::Client.new(access_token: session[:github_token])
    comment = params[:comment]
    case params[:vote]
    when "yes"
      comment += "\n\nVote: ✅"
    when "no"
      comment += "\n\nVote: ❎"
    when "abstention"
      comment += "\n\nVote: 🤐"
    when "block"
      comment += "\n\nVote: 🚫"
    end
    github.add_comment(ENV.fetch("GITHUB_REPO"), @proposal.number, comment)
    redirect_to @proposal
  end

  private
    def get_proposal
      @proposal = Proposal.find_by(number: params[:id])
      raise ActiveRecord::RecordNotFound if @proposal.nil?
    end

    def on_issue_comment(json)
      case json["action"]
      when "created"
        on_issue_comment_created(json)
      end
    end

    def on_pull_request(json)
      case json["action"]
      when "opened"
        on_pull_request_opened(json)
      when "closed"
        on_pull_request_closed(json)
      end
    end

    def on_issue_comment_created(json)
      issue = json["issue"]
      if issue["state"] == "open" && issue["pull_request"]
        UpdateProposalJob.perform_later issue["number"].to_i
      end
    end

    def on_pull_request_opened(json)
      # Delay creation by a few seconds in case the proposal is already being created elsewhere
      # This is necessary because we were getting race conditions in job creation
      CreateProposalJob.set(wait: 5.seconds).perform_later(json["number"].to_i)
    end

    def on_pull_request_closed(json)
      CloseProposalJob.perform_later(json["number"].to_i)
    end
end
