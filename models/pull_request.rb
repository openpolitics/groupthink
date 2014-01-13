require 'github_api'
require 'json'

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
  
  attr_accessor :number, :state, :title, :agree, :disagree
  
  def initialize(number)
    @number = number
    data = redis.get(db_key)
    if data
      data = JSON.parse(data)
      @state = data['state']
      @title = data['title']
      @agree = data['agree']
      @disagree = data['disagree']
    end
  end
  
  def update_from_github!
    pr = self.class.github.pull_requests.get('openpolitics', 'manifesto', @number)
    comments = self.class.github.issues.comments.list 'openpolitics', 'manifesto', issue_id: @number
    @agree = comments.select{|x| x.body.include?(':+1:') || x.body.include?(':thumbsup:')}.count
    @disagree = comments.select{|x| x.body.include?(':-1:') || x.body.include?(':thumbsdown:')}.count
    if @disagree > 0
      @state = "blocked"
    elsif @agree >= 3
      @state = "passed"
    else
      @state = "waiting"
    end
    @title = pr.title
    save!
  end
  
  def db_key
    [self.class.name, number.to_s].join(':')
  end
  
  def save!
    redis.set(db_key, {
      'state' => @state,
      'title' => @title,
      'agree' => @agree,
      'disagree' => @disagree,
    }.to_json)
  end
  
  private
  
  def self.github
    @@github = Github.new user: 'openpolitics', repo: 'manifesto', oauth_token: ENV['GITHUB_OAUTH_TOKEN']    
  end
  
end