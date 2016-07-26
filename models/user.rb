class User < ActiveRecord::Base
  
  has_many :interactions, dependent: :destroy
  has_many :participating, through: :interactions, class_name: "PullRequests"

  validates :login, presence: true, uniqueness: true
  validates :avatar_url, presence: true
  
  before_validation(on: :create) do 
    load_from_github
  end

  def load_from_github
    self.avatar_url ||= Octokit.user(login).avatar_url
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
      user = User.new(login: contributor["login"])
      user.save!
    end
  end
  
  
end