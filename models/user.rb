class User
  
  attr_accessor :login, :avatar_url, :agree, :disagree, :abstain, :participating, :voted, :contributor

  def initialize(login)
    @login = login
    data = redis.get(db_key)
    if data
      data = JSON.parse(data)
      @login         = data['login']
      @avatar_url    = data['avatar_url']
      @agree         = data['agree'] || []
      @disagree      = data['disagree'] || []
      @abstain       = data['abstain'] || []
      @participating = data['participating'] || []
      @voted         = data['voted'] || []
      @contributor   = data['contributor'].nil? ? update_github_contributor_status : data['contributor']
    else
      @agree         = []
      @disagree      = []
      @abstain       = []
      @participating = []
      @voted         = []
      update_github_contributor_status
    end
  end

  def update_github_contributor_status
    conn = Faraday.new(:url => 'https://github.com')
    response = conn.get '/openpolitics/manifesto/graphs/contributors-data'
    json = JSON.parse(response.body)
    @contributor = json.map{|x| x["author"]["login"]}.include? @login
    @contributor
  end

  def self.find_all
    redis.keys.select{|x| x =~ /^User:/}.map{|key| User.find(key.split(':')[1])}.sort_by{|x| x.login}
  end
  
  def self.find(login)
    user = User.new(login)
  end
  
  def agree!(pr)
    pr = pr.to_i
    remove!(pr)
    @agree << pr
    @participating << pr
    @voted << pr
    save!
  end

  def disagree!(pr)
    pr = pr.to_i
    remove!(pr)
    @disagree << pr
    @participating << pr
    @voted << pr
    save!
  end

  def abstain!(pr)
    pr = pr.to_i
    remove!(pr)
    @abstain << pr
    @participating << pr
    @voted << pr
    save!
  end

  def participating!(pr)
    pr = pr.to_i
    remove!(pr)
    @participating << pr
    save!
  end

  def remove!(pr)
    pr = pr.to_i
    @voted.delete(pr)
    @participating.delete(pr)
    @disagree.delete(pr)
    @agree.delete(pr)
    @abstain.delete(pr)
    save!
  end

  def state(pr)
    ['agree', 'abstain', 'disagree', 'participating'].find{|x| instance_variable_get("@#{x}").include?(pr.to_i)}    
  end

  def db_key
    [self.class.name, @login.to_s].join(':')
  end
  
  def save!
    redis.set(db_key, {
      'login'         => @login,
      'avatar_url'    => @avatar_url,
      'agree'         => @agree,
      'disagree'      => @disagree,
      'abstain'       => @abstain,
      'participating' => @participating,
      'voted'         => @voted,
      'contributor'   => @contributor.nil? ? update_github_contributor_status : @contributor
    }.to_json)
  end
  
  
end