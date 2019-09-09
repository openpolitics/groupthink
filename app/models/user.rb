# frozen_string_literal: true

#
# Generic humanoid carbon unit
#
class User < ApplicationRecord
  include UserAdmin

  default_scope { order(:login) }

  devise :omniauthable, omniauth_providers: [:github]

  has_many :interactions, dependent: :destroy
  has_many :participating, through: :interactions, source: :proposal

  validates :login, presence: true, uniqueness: true
  validates :avatar_url, presence: true

  before_validation :load_from_github, on: :create

  enum role: { user: 0, admin: 1 }
  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= :user
  end

  def proposed
    Proposal.where(proposer: self)
  end

  def voted_on
    Proposal.joins(:interactions).
      where('interactions.user': self).
      where.not('interactions.last_vote': nil).
      where.not(proposer: self)
  end

  def not_voted_on
    # There might be a better way to do this
    Proposal.open.
      where.not(proposer: self).
      where.not(id: voted_on)
  end

  def self.from_omniauth(auth)
    # Find by oauth details, or if not available,
    # by login only as some may have been created before.
    u = find_by(provider: auth.provider, uid: auth.uid) || find_by(login: auth.extra.raw_info.login)
    if u.nil?
      u = User.create!(provider: auth.provider, uid: auth.uid, login: auth.extra.raw_info.login)
    end
    u
  end

  def load_from_github
    github_user = Octokit.user(login)
    self.avatar_url = github_user.avatar_url
    self.email ||= github_user.email
    self.author = update_author_status_from_github
    self.role = update_role_from_github
    nil # to avoid halting validation chain until 5.1
  rescue Octokit::NotFound
    # TODO Need to do something here if the user has been deleted,
    # but for now we'll just log an error
    logger.warn "User #{login} not found in GitHub - could have been deleted"
    nil
  end

  def update_role_from_github
    p = Octokit.permission_level(ENV.fetch("GITHUB_REPO"), login).permission rescue nil
    case p
    when "admin"
      self.role = :admin
    else
      self.role = :user
    end
  end

  def update_author_status_from_github
    # TODO fix autopagination not working here: https://github.com/openpolitics/groupthink/issues/176
    @authors ||= Octokit.contributors(ENV.fetch("GITHUB_REPO"), per_page: 100)
    self.author = !@authors.find { |x| x.login == login }.nil?
  end

  def can_vote?
    voter || ((ENV.fetch("ALL_AUTHORS_CAN_VOTE", false) == "true") && author)
  end

  def vote(proposal)
    interactions.find_by(proposal: proposal).try(:state)
  end

  def to_param
    login
  end
end
