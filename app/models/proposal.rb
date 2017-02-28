class Proposal < ApplicationRecord
  include VoteCounter

  has_many :interactions, dependent: :destroy
  has_many :participants, through: :interactions, source: :user
  belongs_to :proposer, class_name: "User"

  validates :number, presence: true, uniqueness: true
  validates :state, inclusion: { in: %w(waiting agreed passed blocked dead accepted rejected)}
  validates :title, presence: true
  validates :proposer, presence: true

  before_validation :load_from_github, on: :create
  after_create :count_votes!
  after_create :notify_voters

  paginates_per 25

  def self.update_all_from_github!
    Rails.logger.info "Updating proposals"
    Octokit.pull_requests(ENV['GITHUB_REPO'], state: "all").each do |pr|
      Rails.logger.info " - #{pr["number"]}: #{pr["title"]}"
      pr = Proposal.find_by_number(pr["number"].to_i)
      pr.update_from_github!
    end
  end

  def update_from_github!
    load_from_github
    count_votes! unless closed?
    save!
  end

  def github_pr
    @github_pr ||= Octokit.pull_request(ENV['GITHUB_REPO'], number)
  end

  def commits
    Octokit.pull_request_commits(ENV['GITHUB_REPO'], number)
  end

  def head_sha
    github_pr["head"]["sha"]
  end
  
  def base_sha
    github_pr["base"]["sha"]
  end
  
  def diff(sha = nil)
    sha ||= head_sha
    Octokit.compare(ENV['GITHUB_REPO'], base_sha, sha).files
  end
  
  def load_from_github
    self.opened_at = github_pr.created_at
    self.title     = github_pr.title
    self.state   ||= "waiting"
    self.proposer  = User.find_or_create_by(login: github_pr.user.login)
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

  def agreed?
    score >= ENV["PASS_THRESHOLD"].to_i
  end
  
  def blocked?
    score < ENV["BLOCK_THRESHOLD"].to_i
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

  def close!
    proposer.update_github_contributor_status and proposer.save!
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
    "https://github.com/#{ENV['GITHUB_REPO']}/pull/#{number}"
  end
  
  def notify_voters
    # Notify users that there is a new proposal to vote on
    User.where.not(email: nil).where(notify_new: true, contributor: true).all.each do |user|
      ProposalsMailer.new_proposal(user, self).deliver_now unless user == proposer
    end
  end
  
  def to_param
    number.to_s
  end
  
end
