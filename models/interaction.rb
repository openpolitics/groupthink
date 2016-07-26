class Interaction < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :pull_request  

  validates :user, presence: true
  validates :pull_request, presence: true
  
  validates :last_vote, inclusion: {in: %w(agree disagree abstain), allow_nil: true}
  
  def agree!
    update_attributes! last_vote: "agree"
  end
  
  def abstain!
    update_attributes! last_vote: "abstain"
  end
  
  def disagree!
    update_attributes! last_vote: "disagree"
  end
  
  def state
    last_vote || "participating"
  end
  
end