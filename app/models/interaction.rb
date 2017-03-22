class Interaction < ApplicationRecord
  
  belongs_to :user
  belongs_to :proposal  

  validates :user, presence: true
  validates :proposal, presence: true
  
  validates :last_vote, inclusion: {in: %w(yes block no abstention), allow_nil: true}
  
  def yes!
    update_attributes! last_vote: "yes"
  end
  
  def no!
    update_attributes! last_vote: "no"
  end
  
  def abstention!
    update_attributes! last_vote: "abstention"
  end
  
  def block!
    update_attributes! last_vote: "block"
  end
  
  def state
    last_vote || "participating"
  end
  
end