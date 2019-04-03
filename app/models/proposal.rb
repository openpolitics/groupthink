# frozen_string_literal: true

class Proposal < ApplicationRecord
  include VoteCounter
  include GithubPullRequest

  default_scope { order(number: :desc) }
  paginates_per 10

  has_many :interactions, dependent: :destroy
  has_many :participants, through: :interactions, source: :user
  belongs_to :proposer, class_name: "User"

  validates :number, presence: true, uniqueness: true
  validates :state, inclusion: { in: %w(waiting agreed passed blocked dead accepted rejected) }
  validates :title, presence: true
  validates :proposer, presence: true

  before_validation :load_from_github, on: :create
  after_create :queue_vote_count
  after_create :notify_voters

  def queue_vote_count
    VoteCounterJob.perform_later self
  end

  def self.update_all_from_github!
    Rails.logger.info "Updating proposals"
    Octokit.pull_requests(ENV["GITHUB_REPO"], state: "all").each do |pr|
      Rails.logger.info " - #{pr["number"]}: #{pr["title"]}"
      pr = Proposal.find_or_create_by(number: pr["number"].to_i)
      pr.update_from_github!
    end
  end

  def update_from_github!
    load_from_github
    count_votes! unless closed?
    save!
  end

  def description
    github_pr.body
  end

  def submitted_at
    github_pr.created_at
  end

  def load_from_github
    self.opened_at ||= github_pr.created_at
    self.title     ||= github_pr.title
    self.state     ||= "waiting"
    self.proposer  ||= User.find_or_create_by(login: github_pr.user.login)
  end

  def age
    (Date.today - opened_at.to_date).to_i
  end

  def too_old?
    age >= ENV["MAX_AGE"].to_i
  end

  def too_new?
    age < ENV["MIN_AGE"].to_i
  end

  def score
    (yes.count * ENV["YES_WEIGHT"].to_i) + (no.count * ENV["NO_WEIGHT"].to_i) + (block.count * ENV["BLOCK_WEIGHT"].to_i)
  end

  def passed?
    score >= ENV["PASS_THRESHOLD"].to_i
  end

  def blocked?
    score < ENV["BLOCK_THRESHOLD"].to_i
  end

  def update_state!
    # default
    state = "waiting"
    # If closed, was it accepted or rejected?
    if pr_closed?
      state = pr_merged? ? "accepted" : "rejected"
    else
      if too_old?
        state = "dead"
      elsif blocked?
        state = "blocked"
      elsif passed?
        state = too_new? ? "agreed" : "passed"
      end
    end
    # Store final state in DB
    update_attributes!(state: state)
  end

  def merge_if_passed!
    merge_pr! if state == "passed"
  end

  def close_if_dead!
    close_pr! if state == "dead"
  end

  def yes
    interactions.where(last_vote: "yes")
  end

  def block
    interactions.where(last_vote: "block")
  end

  def no
    interactions.where(last_vote: "no")
  end

  def abstention
    interactions.where(last_vote: "abstention")
  end

  def close!
    proposer.update_github_contributor_status && proposer.save!
    update_state!
  end

  def closed?
    %w(accepted rejected).include? state
  end

  def self.closed
    self.where(state: %w(accepted rejected))
  end

  def self.open
    self.where(state: %w(waiting agreed passed blocked dead))
  end

  def url
    github_url
  end

  def notify_voters
    # Notify users that there is a new proposal to vote on
    User.where.not(email: nil).where(notify_new: true, contributor: true).all.each do |user|
      ProposalsMailer.new_proposal(user, self).deliver_later unless user == proposer
    end
  end

  def to_param
    number.to_s
  end

  def activity_log
    activity = []
    # Add commits
    activity.concat(github_commits.map { |commit|
      ["diff", {
        sha: commit[:sha],
        user: User.find_by_login(commit[:commit][:author][:name]),
        proposal: self,
        original_url: url,
        time: commit[:commit][:author][:date]
      }]
    })
    # Add original description
    activity << ["comment", {
      body: description,
      user: proposer,
      by_author: true,
      original_url: url,
      time: submitted_at
    }] if description
    # Add comments
    activity.concat(github_comments.map { |comment|
      next if comment.body =~ /votebot instructions/
      ["comment", {
        body: comment.body,
        user: User.find_by_login(comment.user.login),
        by_author: (comment.user.login == proposer.login),
        original_url: comment.html_url,
        time: comment.created_at
      }]
    })
    # Remove any empty elements
    activity.compact!
    # Sort by time
    activity.sort_by { |a| a[1][:time] }
  end

  def diff(sha)
    github_diff(sha)
  end

  def repo
    github_repo
  end

  def branch
    github_branch
  end
end
