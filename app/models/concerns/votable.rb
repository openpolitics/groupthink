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
      yes: ENV.fetch("YES_WEIGHT").to_i,
      no: ENV.fetch("NO_WEIGHT").to_i,
      block: ENV.fetch("BLOCK_WEIGHT").to_i,
    }
    interactions.all.inject(0) do |sum, i|
      sum + (weights[i.last_vote.try(:to_sym)] || 0)
    end
  end

  def passed?
    score >= ENV.fetch("PASS_THRESHOLD").to_i
  end

  def blocked?
    score < ENV.fetch("BLOCK_THRESHOLD").to_i
  end

  private

    INSTRUCTION_HEADER = "<!-- votebot instructions -->"

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
      if Regexp.new(INSTRUCTION_HEADER).match?(comment.body)
        return
      end
      # Find the user
      user = User.find_or_create_by!(login: comment.user.login)
      # Ignore proposer and non-contributors
      if user == proposer || !user.contributor
        return
      end
      # Votes are stores in an interaction record
      interaction = interactions.find_or_create_by!(user: user)
      # It's a yes if there is a yes vote AND the comment is since the last commit
      if comment.body.contains_yes?
        if comment.created_at >= time_of_last_commit
          interaction.yes!
        else
          interaction.update_attributes!(last_vote: nil)
        end
      end
      if comment.body.contains_abstention?
        interaction.abstention!
      end
      if comment.body.contains_no?
        interaction.no!
      end
      if comment.body.contains_block?
        interaction.block!
      end
    end

    def count_votes_in_comments(comments)
      comments.each { |c| count_vote_in_comment(c, time_of_last_commit) }
    end

    def post_instructions
      vars = {
        site_url: ENV.fetch("SITE_URL"),
        yes_weight: ENV.fetch("YES_WEIGHT"),
        no_weight: ENV.fetch("NO_WEIGHT"),
        block_weight: ENV.fetch("BLOCK_WEIGHT"),
        pass_threshold: ENV.fetch("PASS_THRESHOLD"),
        min_age: ENV.fetch("MIN_AGE"),
        max_age: ENV.fetch("MAX_AGE"),
        proposal_number: number,
        repo: ENV.fetch("GITHUB_REPO"),
        proposer: proposer.login,
      }
      instructions = [INSTRUCTION_HEADER, I18n.t("help.instruction_comment", vars)].join("\n")
      github_add_comment instructions
    end
end
