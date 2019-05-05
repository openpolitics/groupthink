# frozen_string_literal: true

#
# A proposed change to the repository.
# Underneath, this is a GitHub pull request.
#
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

  scope :closed, -> { where(state: %w(accepted rejected)) }
  scope :open, -> { where(state: %w(waiting agreed passed blocked dead)) }

  def self.update_all_from_github!
    Rails.logger.info "Updating proposals"
    Octokit.pull_requests(ENV.fetch("GITHUB_REPO"), state: "all").each do |pr|
      Rails.logger.info " - #{pr["number"]}: #{pr["title"]}"
      pr = Proposal.find_or_create_by!(number: pr["number"].to_i)
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
    self.proposer  ||= User.find_or_create_by!(login: github_pr.user.login)
  end

  def age
    (Date.today - opened_at.to_date).to_i
  end

  def too_old?
    age >= ENV.fetch("MAX_AGE").to_i
  end

  def too_new?
    age < ENV.fetch("MIN_AGE").to_i
  end

  def score
    weights = {
      yes: ENV.fetch("YES_WEIGHT").to_i,
      no: ENV.fetch("NO_WEIGHT").to_i,
      block: ENV.fetch("BLOCK_WEIGHT").to_i,
    }
    interactions.all.inject(0) do |sum, i|
      sum + (weights[i.last_vote.try(:to_sym)] || 0)
    end
  end

  def passed?
    score >= ENV.fetch("PASS_THRESHOLD").to_i
  end

  def blocked?
    score < ENV.fetch("BLOCK_THRESHOLD").to_i
  end

  def update_state!
    state = pr_closed? ? closed_state : open_state
    update_attributes!(state: state)
  end

  def merge_if_passed!
    merge_pr! if state == "passed"
  end

  def close_if_dead!
    close_pr! if state == "dead"
  end

  def close!
    proposer.update_github_contributor_status && proposer.save!
    update_state!
  end

  def closed?
    %w(accepted rejected).include? state
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

  def diff(sha)
    github_diff(sha)
  end

  def repo
    github_repo
  end

  def branch
    github_branch
  end

  private

    def closed_state
      return nil unless pr_closed?
      pr_merged? ? "accepted" : "rejected"
    end

    def open_state
      return nil if pr_closed?
      return "dead" if too_old?
      return "blocked" if blocked?
      if passed?
        return too_new? ? "agreed" : "passed"
      end
      "waiting"
    end
end
