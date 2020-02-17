# frozen_string_literal: true

#
# Methods for models that can be voted on
#
module Votable
  extend ActiveSupport::Concern

  def queue_vote_count
    VoteCounterJob.perform_later self
  end

  def score
    weights = {
      yes: Rules.yes_weight,
      no: Rules.no_weight,
      block: Rules.block_weight,
    }
    interactions.all.inject(0) do |sum, i|
      sum + (weights[i.last_vote.try(:to_sym)] || 0)
    end
  end

  def passed?
    score >= Rules.pass_threshold
  end

  def blocked?
    score < Rules.block_threshold
  end

  def count_votes!
    comments = github_comments
    # Post instructions if they're not already there
    if !instructions_posted?(comments) && !pr_closed?
      post_instructions
    end
    # Count up all the votes
    count_votes_in_comments(comments)
    # Update the state flag
    update_state!
    # Set build statuses on github
    unless closed?
      set_vote_build_status
      set_time_build_status
    end
  end

  private
    INSTRUCTION_HEADER = "<!-- votebot instructions -->"

    def instructions_posted?(comments)
      instructions_found = false
      comments.each do |c|
        if Regexp.new(INSTRUCTION_HEADER).match?(c.body)
          instructions_found = true
        end
      end
      instructions_found
    end

    def count_vote_in_comment(comment, time_of_last_commit)
      # Skip instructions
      return if Regexp.new(INSTRUCTION_HEADER).match?(comment.body)
      # Ignore proposer and non-voters
      user = User.find_or_create_by!(login: comment.user.login)
      return if user == proposer || !user.can_vote?
      # Store vote in an interaction record
      interaction = interactions.find_or_create_by!(user: user)
      interaction.set_last_vote_from_comment!(comment, time_of_last_commit)
    end

    def count_votes_in_comments(comments)
      comments.each { |c| count_vote_in_comment(c, time_of_last_commit) }
    end

    def post_instructions
      vars = {
        site_url: ENV.fetch("SITE_URL"),
        proposal_number: number,
        repo: ENV.fetch("GITHUB_REPO"),
        proposer: proposer.login,
      }.merge(Rules)
      github_add_comment [INSTRUCTION_HEADER, I18n.t("help.instruction_comment", vars)].join("\n")
    end
end
