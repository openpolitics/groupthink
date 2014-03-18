require 'github_api'
require 'json'

class PullRequest

  States = [
    "passed",
    "waiting",
    "blocked"
  ]
  
  def self.update_all_from_github!
    redis.del(redis.keys('PullRequest:*'))
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
  
  def self.find(number)
    pr = PullRequest.new(number)
    pr.state ? pr : nil
  end
  
  attr_accessor :number, :state, :title, :agree, :disagree, :abstain, :proposer, :participants
  
  def initialize(number)
    @number = number
    data = redis.get(db_key)
    if data
      data = JSON.parse(data)
      @proposer = data['proposer']
      @state = data['state']
      @title = data['title']
      @participants = data['participants']
      @agree = data['agree']
      @disagree = data['disagree']
      @abstain = data['abstain']
    end
  end
  
  def update_from_github!
    pr = self.class.github.pull_requests.get('openpolitics', 'manifesto', @number)
    comments = self.class.github.issues.comments.list 'openpolitics', 'manifesto', issue_id: @number
    @proposer = pr.user
    @participants = comments.map{|x| x.user}.uniq
    @agree = comments.select{|x| x.body.include?(':+1:') || x.body.include?(':thumbsup:')}.map{|x| x.user}.uniq
    @disagree = comments.select{|x| x.body.include?(':-1:') || x.body.include?(':thumbsdown:')}.map{|x| x.user}.uniq
    @abstain = comments.select{|x| x.body.include?(':hand:')}.map{|x| x.user}.uniq
    github_state = nil
    github_description = nil
    if @disagree.count > 0
      @state = "blocked"
      github_state = "failure"
      github_description = "The change is blocked"
    elsif @agree.count >= 2
      @state = "passed"
      github_state = "success"
      github_description = "The change is approved and ready to merge"
    else
      @state = "waiting"
      github_state = "pending"
      github_description = "The change is waiting for more votes"
    end
    @title = pr.title
    save!
    # Update github commit status
    self.class.github.repos.statuses.create 'openpolitics', 'manifesto', pr['head']['sha'],
      "state" =>  github_state,
      "target_url" => "http://votebot.openpolitics.org.uk/#{@number}",
      "description" => github_description
  end
  
  def db_key
    [self.class.name, number.to_s].join(':')
  end
  
  def save!
    redis.set(db_key, {
      'proposer' => @proposer,
      'state' => @state,
      'title' => @title,
      'participants' => @participants,
      'agree' => @agree,
      'disagree' => @disagree,
      'abstain' => @abstain,
    }.to_json)
  end
  
  def delete!
    redis.del(db_key)
  end
  
  private
  
  def self.github
    @@github = Github.new user: 'openpolitics', repo: 'manifesto', oauth_token: ENV['GITHUB_OAUTH_TOKEN']    
  end
  
end