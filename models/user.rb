class User
  
  attr_accessor :login, :avatar_url, :agree, :disagree, :abstain, :participating

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
    else
      @agree         = []
      @disagree      = []
      @abstain       = []
      @participating = []
    end
  end

  def self.find_all
    redis.keys.select{|x| x =~ /^User:/}.map{|key| User.new(key.split(':')[1])}.sort_by{|x| x.login}
  end
  
  def self.find(login)
    user = User.new(login)
  end
  
  def agree!(pr)
    remove!(pr)
    @agree << pr
    @participating << pr
    save!
  end

  def disagree!(pr)
    remove!(pr)
    @disagree << pr
    @participating << pr
    save!
  end

  def abstain!(pr)
    remove!(pr)
    @abstain << pr
    @participating << pr
    save!
  end

  def participating!(pr)
    remove!(pr)
    @participating << pr
    save!
  end

  def remove!(pr)
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
    }.to_json)
  end
  
  
end