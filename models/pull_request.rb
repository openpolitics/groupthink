require 'github_api'
require 'json'

class PullRequest

  States = [
    "passed",
    "waiting",
    "blocked"
  ]
  
  def self.update_all_from_github!
    keys = redis.keys('PullRequest:*')
    redis.del(keys) unless keys.empty?
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
    @proposer = pr.user
    process_comments
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
  
  def process_comments
    comments = self.class.github.issues.comments.list 'openpolitics', 'manifesto', issue_id: @number
    @participants = []
    @agree = []
    @abstain = []
    @disagree = []
    comments.each do |comment|
      user = comment.user
      if user != @proposer
        @participants << user
        case comment.body
        when /:thumbsup:|:\+1:/
          remove_votes(user)
          @agree << user
        when /:hand:/
          remove_votes(user)
          @abstain << user
        when /:thumbsdown:|:\-1:/
          remove_votes(user)
          @disagree << user
        end
      end
    end
    @participants.uniq!
  end
  
  def remove_votes(user)
    @agree.delete(user)
    @abstain.delete(user)
    @disagree.delete(user)
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