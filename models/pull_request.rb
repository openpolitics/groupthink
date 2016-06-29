require 'octokit'
require 'json'

class PullRequest

  States = [
    "passed",
    "waiting",
    "agreed",
    "blocked",
    "dead"
  ]

  def self.update_all_from_github!
    keys = redis.keys('PullRequest:*')
    redis.del(keys) unless keys.empty?
    Octokit.pull_requests(ENV['GITHUB_REPO']).each do |pr|
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
    pr = Octokit.pull_request(ENV['GITHUB_REPO'], @number)
    @proposer = pr.user.login
    @created_at = pr.created_at
    process_comments(pr.head.sha)
    required_agrees = 2
    github_state = nil
    github_description = nil
    votes = @agree.count - @abstain.count
    if @disagree.count > 0
      @state = "blocked"
      github_state = "failure"
      github_description = "The change is blocked."
    elsif votes >= required_agrees
      @state = "passed"
      github_state = "success"
      github_description = "The change is agreed."
    else
      @state = "waiting"
      github_state = "pending"
      github_description = "The change is waiting for more votes; #{required_agrees - votes} more needed."
    end
    # Update github commit status
    Octokit.create_status(ENV['GITHUB_REPO'], pr.head.sha, github_state,
      target_url: "http://votebot.openpolitics.org.uk/#{@number}",
      description: github_description,
      context: "votebot/votes")
    # Check age
    if age >= 90
      @state = "dead"
      github_state = "failure"
      github_description = "The change has been open for more than 90 days, and should be closed."
    elsif age >= 7
      github_state = "success"
      github_description = "The change has been open long enough to be merged."
    else
      @state = "agreed" if @state == "passed"
      github_state = "pending"
      github_description = "The change has not yet been open for 7 days."
    end
    # Update github commit status
    Octokit.create_status(ENV['GITHUB_REPO'], pr.head.sha, github_state,
      target_url: "http://votebot.openpolitics.org.uk/#{@number}",
      description: github_description,
      context: "votebot/time")
    @title = pr.title
    save!
  end

  def process_comments(sha = nil)
    comments = Octokit.issue_comments(ENV['GITHUB_REPO'], @number)
    if sha
      commit = Octokit.pull_commits(ENV['GITHUB_REPO'], @number).find{|x| x.sha == sha}
      cutoff = commit.commit.committer.date
    else
      cutoff = DateTime.new(1970)
    end
    @participants = []
    @agree = []
    @abstain = []
    @disagree = []
    comments.each do |comment|
      user = comment.user.login
      db_user = User.find(user)
      if user != @proposer
        unless @participants.include?(user)
          @participants << user
          db_user.participating!(@number)
        end
        if db_user.contributor
          case comment.body
          when /:thumbsup:|:\+1:|👍/
            next if comment.created_at < cutoff
            remove_votes(user)
            @agree << user
            db_user.agree!(@number)
          when /:hand:|✋/
            remove_votes(user)
            @abstain << user
            db_user.abstain!(@number)
          when /:thumbsdown:|:\-1:|👎/
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
    User.find(user).remove!(@number)
  end

  def db_key
    [self.class.name, number.to_s].join(':')
  end

  def age
    (Date.today - @created_at.to_date).to_i
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

end
