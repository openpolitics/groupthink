# frozen_string_literal: true

#
# A proposed change to the repository.
# Underneath, this is a GitHub pull request.
#
class Proposal < ApplicationRecord
  include Votable
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

  def update_from_github!
    load_from_github
    count_votes! unless closed?
    save!
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
    age >= Rules.max_age
  end

  def too_new?
    age < Rules.min_age
  end

  def update_state!
    state = pr_closed? ? closed_state : open_state
    update!(state: state)
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

  def notify_voters
    # Notify users that there is a new proposal to vote on
    User.where.not(email: nil).where(notify_new: true, contributor: true).all.find_each do |user|
      ProposalsMailer.new_proposal(user, self).deliver_later unless user == proposer
    end
  end

  def to_param
    number.to_s
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
