class PullRequest

  States = [
    "passed",
    "waiting",
    "blocked"
  ]
  
  def self.update_from_github!(number)
    pr = PullRequest.new(number)
    pr.update_from_github!
    pr
  end
  
  attr_accessor :number
  attr_accessor :state
  
  def initialize(number)
    @number = number
  end
  
  def update_from_github!
    @state = "passed"
  end
  
end