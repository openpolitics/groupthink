class PullRequest
  
  def self.update_from_github!(number)
    PullRequest.new(number).update_from_github!
  end
  
  attr_accessor :number
  
  def initialize(number)
    @number = number
  end
  
  def update_from_github!
    puts number
  end
  
end