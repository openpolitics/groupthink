require 'octokit'
require 'json'

class PullRequest < ActiveRecord::Base

  include VoteCounter

  has_many :interactions, dependent: :destroy
  has_many :participants, through: :interactions, source: :user
  belongs_to :proposer, class_name: "User"

  validates :number, presence: true, uniqueness: true
  validates :state, inclusion: { in: %w(waiting agreed passed blocked dead)}
  validates :title, presence: true
  validates :proposer, presence: true

  before_validation(on: :create) do 
    load_from_github
  end

  def self.recreate_all_from_github!
    PullRequest.delete_all
    Octokit.pull_requests(ENV['GITHUB_REPO']).each do |pr|
      create_from_github!(pr["number"])
    end
  end

  def self.create_from_github!(number)
    pr = PullRequest.find_or_create_by!(number: number)
    pr.count_votes!
    pr
  end
  
  def github_pr
    @github_pr ||= Octokit.pull_request(ENV['GITHUB_REPO'], number)
  end
  
  def sha
    @sha ||= github_pr.head.sha
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
    destroy
  end

end
