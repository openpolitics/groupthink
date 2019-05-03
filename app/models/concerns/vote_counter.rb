# frozen_string_literal: true

#
# Methods for models that can be voted on
#
module VoteCounter
  extend ActiveSupport::Concern

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

    def set_vote_build_status
      if blocked?
        status = :failure
        text = I18n.t("build_status.votes.blocked")
      elsif passed?
        status = :success
        text = I18n.t("build_status.votes.agreed")
      else
        remaining_votes = ENV.fetch("PASS_THRESHOLD").to_i - score
        status = :pending
        text = I18n.t("build_status.votes.waiting", remaining: remaining_votes)
      end
      # Update github commit status
      set_build_status(status, text, "groupthink/votes")
    end

    def set_time_build_status
      # Check age
      if too_old?
        status = :failure
        text = I18n.t("build_status.time.too_old", max_age: ENV.fetch("MAX_AGE"), age: age)
      elsif too_new?
        status = :pending
        text = I18n.t("build_status.time.too_new", min_age: ENV.fetch("MIN_AGE"), age: age)
      else
        status = :success
        text = I18n.t("build_status.time.success", age: age)
      end
      # Update github commit status
      set_build_status(status, text, "groupthink/time")
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
