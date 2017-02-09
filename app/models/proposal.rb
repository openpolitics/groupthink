class Proposal < ApplicationRecord

  include VoteCounter

  has_many :interactions, dependent: :destroy
  has_many :participants, through: :interactions, source: :user
  belongs_to :proposer, class_name: "User"

  validates :number, presence: true, uniqueness: true
  validates :state, inclusion: { in: %w(waiting agreed passed blocked dead accepted rejected)}
  validates :title, presence: true
  validates :proposer, presence: true

  before_validation(on: :create) do 
    load_from_github
  end

  def self.recreate_all_from_github!
    Rails.logger.info "Removing all proposals"
    Proposal.delete_all
    Rails.logger.info "Loading proposals"
    Octokit.pull_requests(ENV['GITHUB_REPO'], state: "all").each do |pr|
      Rails.logger.info " - #{pr["number"]}: #{pr["title"]}"
      create_from_github!(pr["number"])
    end
  end

  def self.create_from_github!(number)
    pr = Proposal.find_or_create_by!(number: number)
    pr.count_votes! unless pr.closed?
    pr
  end
  
  def github_pr
    @github_pr ||= Octokit.pull_request(ENV['GITHUB_REPO'], number)
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

  def agree
    interactions.where(last_vote: "agree")
  end
  
  def disagree
    interactions.where(last_vote: "disagree")
  end
  
  def abstain
    interactions.where(last_vote: "abstain")
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
    "https://github.com/#{ENV['GITHUB_REPO']}/pull/#{@proposal.number}"
  
end
