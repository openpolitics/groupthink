require 'github_api'
require 'json'

class PullRequest

  States = [
    "passed",
    "waiting",
    "agreed",
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

  attr_accessor :number, :state, :title, :agree, :disagree, :abstain, :proposer, :participants, :created_at

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
      @created_at = Date.parse data['created_at']
    end
  end
  
  def update_from_github!
    pr = self.class.github.pull_requests.get('openpolitics', 'manifesto', @number)
    @proposer = pr.user
    @created_at = Date.parse pr.created_at
    process_comments(pr.head.sha)
    required_agrees = (User.where(contributor: true).count * 0.2).to_i
    github_state = nil
    github_description = nil
    if @disagree.count > 0
      @state = "blocked"
      github_state = "failure"
      github_description = "The change is blocked"
    elsif @agree.count >= required_agrees && age >= 14
      @state = "passed"
      github_state = "success"
      github_description = "The change is approved and ready to merge"
    elsif @agree.count < required_agrees
      @state = "waiting"
      github_state = "pending"
      github_description = "The change is waiting for more votes"
    else
      @state = "agreed"
      github_state = "pending"
      github_description = "The change has not yet been open for 14 days"
    end
    @title = pr.title
    save!
    # Update github commit status
    self.class.github.repos.statuses.create 'openpolitics', 'manifesto', pr['head']['sha'],
      "state" =>  github_state,
      "target_url" => "http://votebot.openpolitics.org.uk/#{@number}",
      "description" => github_description,
      "context" => "votebot"
  end

  def process_comments(sha = nil)
    comments = self.class.github.issues.comments.list 'openpolitics', 'manifesto', issue_id: @number
    if sha
      commit = self.class.github.repos.commits.get 'openpolitics', 'manifesto', sha
      cutoff = DateTime.parse(commit.commit.committer.date)
    else
      cutoff = DateTime.new(1970)
    end
    @participants = []
    @agree = []
    @abstain = []
    @disagree = []
    comments.each do |comment|
      user = comment.user
      db_user = User.find(user.login)
      if user != @proposer
        unless @participants.include?(user)
          @participants << user
          db_user.participating!(@number)
        end
        if db_user.contributor
          case comment.body
          when /:thumbsup:|:\+1:/
            next if DateTime.parse(comment.created_at) < cutoff
            remove_votes(user)
            @agree << user
            db_user.agree!(@number)
          when /:hand:/
            remove_votes(user)
            @abstain << user
            db_user.abstain!(@number)
          when /:thumbsdown:|:\-1:/
            remove_votes(user)
            @disagree << user
            db_user.disagree!(@number)
          end
        end
      end
    end
    @participants.uniq!
  end

  def remove_votes(user)
    @agree.delete(user)
    @abstain.delete(user)
    @disagree.delete(user)
    User.find(user.login).remove!(@number)
  end

  def db_key
    [self.class.name, number.to_s].join(':')
  end

  def age
    (Date.today - created_at).to_i
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
      'created_at' => @created_at.iso8601,
    }.to_json)
  end

  def delete!
    (participants||[]).each do |user|
      u = User.find(user.is_a?(Hash) ? user['login'] : user.login)
      u.remove!(@number) if u
    end
    redis.del(db_key)
  end

  private

  def self.github
    @@github = Github.new user: 'openpolitics', repo: 'manifesto', oauth_token: ENV['GITHUB_OAUTH_TOKEN']
  end

end
