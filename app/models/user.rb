class User < ApplicationRecord
  
  devise :omniauthable, :omniauth_providers => [:github]

  has_many :interactions, dependent: :destroy
  has_many :participating, through: :interactions, source: :proposal

  validates :login, presence: true, uniqueness: true
  validates :avatar_url, presence: true
  
  before_validation(on: :create) do 
    load_from_github
  end

  def self.from_omniauth(auth)
    # Find by oauth details, or if not available, by login only as some may have been created before.
    u = find_by(provider: auth.provider, uid: auth.uid) || find_by(login: auth.extra.raw_info.login)
    if u.nil?
      u.create(provider: auth.provider, uid: auth.uid, login: auth.extra.raw_info.login)
    end
    u
  end

  def load_from_github
    github_user = Octokit.user(login)
    self.avatar_url = github_user.avatar_url
    self.email = github_user.email
    self.contributor = update_github_contributor_status
    nil # to avoid halting validation chain until 5.1
  end

  def update_github_contributor_status
    @contributors ||= Octokit.contributors(ENV["GITHUB_REPO"])
    self.contributor = !@contributors.find{|x| x.login == login}.nil?
  end
  
  def state(proposal)
    interactions.find_by(proposal: proposal).try(:state)
  end

  def self.update_all_from_github!
    Rails.logger.info "Updating existing users"
    User.all.each do |user|
      Rails.logger.info " - #{user.login}"
      user.load_from_github and user.save!
    end
    Rails.logger.info "Updating new contributors from GitHub"
    Octokit.contributors(ENV["GITHUB_REPO"]).each do |contributor|
      params = {login: contributor["login"]}
      unless User.find_by(params)
        Rails.logger.info " - #{contributor["login"]}"
        user = User.create(params)
        user.contributor = true
        user.save!
      end
    end
  end
  
  def to_param
    login
  end
  
end