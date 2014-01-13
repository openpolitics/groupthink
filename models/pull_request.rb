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
  
  def self.find_all
    redis.keys.select{|x| x =~ /^PullRequest:/}.map{|key| PullRequest.new(key.split(':')[1])}.sort_by{|x| x.number}
  end
  
  attr_accessor :number
  attr_accessor :state
  
  def initialize(number)
    @number = number
    data = JSON.parse(redis.get(db_key))
    @state = data['state']
  end
  
  def update_from_github!
    @state = "passed"
    save!
  end
  
  def db_key
    [self.class.name, number.to_s].join(':')
  end
  
  def save!
    redis.set(db_key, {
      'state' => @state,
    }.to_json)
  end
  
  private
  
  def self.github
    @@github = Github.new user: 'openpolitics', repo: 'manifesto', oauth_token: ENV['GITHUB_OAUTH_TOKEN']    
  end
  
end