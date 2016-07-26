class User < ActiveRecord::Base
  
  has_many :interactions, dependent: :destroy
  has_many :participating, through: :interactions, source: :pull_request

  validates :login, presence: true, uniqueness: true
  validates :avatar_url, presence: true
  
  before_validation(on: :create) do 
    load_from_github
  end

  def load_from_github
    github_user = Octokit.user(login)
    self.avatar_url ||= github_user.avatar_url
    self.email ||= github_user.email
    self.contributor = update_github_contributor_status
    nil # to avoid halting validation chain until 5.1
  end

  def update_github_contributor_status
    @contributors ||= Octokit.contributors(ENV["GITHUB_REPO"])
    self.contributor = !@contributors.find{|x| x.login == login}.nil?
  end
  
  def state(pr)
    interactions.find_by(pull_request: pr).try(:state)
  end

  def self.update_all_from_github!
    User.all.each do |user|
      user.load_from_github and user.save!
    end
    Octokit.contributors(ENV["GITHUB_REPO"]).each do |contributor|
      user = User.find_or_create_by!(login: contributor["login"])
      user.contributor = true
      user.save!
    end
  end
  
  
end