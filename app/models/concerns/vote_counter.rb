module VoteCounter
  extend ActiveSupport::Concern
  
  private

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
      status = "failure"
      text = "The proposal is blocked."
    elsif passed?
      status = "success"
      text = "The proposal has been agreed."
    else
      status = "pending"
      text = "The proposal is waiting for more votes; #{ENV["PASS_THRESHOLD"].to_i - score} more needed."
    end
    # Update github commit status
    set_build_status(status, text, "votebot/votes")
  end

  def set_time_build_status
    # Check age
    if too_old?
      status = "failure"
      text = "The change has been open for more than #{ENV["MAX_AGE"]} days, and should be closed (age: #{age}d)."
    elsif too_new?
      status = "pending"
      text = "The change has not yet been open for #{ENV["MIN_AGE"]} days (age: #{age}d)."
    else
      status = "success"
      text = "The change has been open long enough to be merged (age: #{age}d)."
    end
    # Update github commit status
    set_build_status(status, text, "votebot/time")    
  end

  def instructions_posted?(comments)
    instructions_found = false
    comments.each do |c|
      if c.body =~ /<!-- votebot instructions -->/
        instructions_found = true
      end
    end
    instructions_found
  end

  def count_vote_in_comment(comment, time_of_last_commit)
    # Skip instructions
    if comment.body =~ /<!-- votebot instructions -->/
      return
    end
    # Find the user
    user = User.find_or_create_by(login: comment.user.login)
    # Ignore proposer and non-contributors
    if user == proposer || !user.contributor
      return 
    end
    # Votes are stores in an interaction record 
    interaction = interactions.find_or_create_by!(user: user)
    # It's a yes if there is a yes vote AND the comment is since the last commit
    if comment.body.contains_yes?
      if (comment.created_at >= time_of_last_commit)
        interaction.yes!
      else
        interaction.update_attributes!(last_vote: nil)
      end
    end
    if comment.body.contains_abstain?
      interaction.abstain! 
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
    github_add_comment <<-EOF
<!-- votebot instructions -->
This proposal is open for discussion and voting. If you are a [contributor](#{ENV['SITE_URL']}/users/) to this repository (and not the proposer), you may vote on whether or not it is accepted. 

## How to vote
Vote by entering one of the following symbols in a comment on this pull request. Only your last vote will be counted, and you may change your vote at any time until the change is accepted or closed.

|vote|symbol|type this|points|
|--|--|--|--|
|Yes|:white_check_mark:|`:white_check_mark:`|#{ENV["YES_WEIGHT"]}|
|No|:negative_squared_cross_mark:|`:negative_squared_cross_mark:`|#{ENV["NO_WEIGHT"]}|
|Abstain|:zipper_mouth_face:|`:zipper_mouth_face:`|0|
|Block|:no_entry_sign:|`:no_entry_sign:`|#{ENV["BLOCK_WEIGHT"]}|

Proposals will be accepted and merged once they have a total of #{ENV["PASS_THRESHOLD"]} points when all votes are counted. Votes will be open for a minimum of #{ENV["MIN_AGE"]} days, but will be closed if the proposal is not accepted after #{ENV["MAX_AGE"]}.

Votes are counted [automatically here](#{ENV['SITE_URL']}/proposals/#{number}), and results are set in the merge status checks below.

## Changes

@#{proposer.login}, if you want to make further changes to this proposal, you can do so by [clicking on the pencil icons here](https://github.com/#{ENV['GITHUB_REPO']}/pull/#{number}/files). If a change is made to the proposal, no votes cast before that change will be counted, and votes must be recast.
EOF
  end

end