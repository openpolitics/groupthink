# frozen_string_literal: true

#
# An interaction between a User and a Proposal.
# Records whether a user is voting, or just commenting, and if voting, how.
#
class Interaction < ApplicationRecord
  belongs_to :user
  belongs_to :proposal

  validates :user, presence: true
  validates :proposal, presence: true

  validates :last_vote, inclusion: { in: %w(yes block no abstention), allow_nil: true }

  scope :yes, -> { where(last_vote: "yes") }
  scope :no, -> { where(last_vote: "no") }
  scope :abstention, -> { where(last_vote: "abstention") }
  scope :block, -> { where(last_vote: "block") }
  scope :participating, -> { where(last_vote: nil) }

  def state
    last_vote || "participating"
  end

  def set_last_vote_from_comment!(comment, time_of_last_commit)
    last_vote = nil
    # It's a yes if there is a yes vote AND the comment is since the last commit
    if comment.body.contains_yes? && comment.created_at >= time_of_last_commit
      last_vote = "yes"
    end
    last_vote = "abstention" if comment.body.contains_abstention?
    last_vote = "no" if comment.body.contains_no?
    last_vote = "block"  if comment.body.contains_block?
    update_attributes! last_vote: last_vote
  end
end
