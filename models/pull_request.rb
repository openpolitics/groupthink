require 'github_api'

class PullRequest

  States = [
    "passed",
    "waiting",
    "blocked"
  ]
  
  def self.update_all_from_github!
    github.pull_requests.list.each do |pr|
      update_from_github!(pr["number"])
    end
  end

  def self.update_from_github!(number)
    pr = PullRequest.new(number)
    pr.update_from_github!
    pr
  end
  
  attr_accessor :number
  attr_accessor :state
  
  def initialize(number)
    @number = number
    @state = redis.get(db_key)
  end
  
  def update_from_github!
    @state = "passed"
    redis.set(db_key, @state)
  end
  
  def db_key
    [self.class.name, number.to_s].join(':')
  end
  
  
  private
  
  def self.github
    @@github = Github.new user: 'openpolitics', repo: 'manifesto', oauth_token: ENV['GITHUB_OAUTH_TOKEN']    
  end
  
end