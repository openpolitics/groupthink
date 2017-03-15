module VoteCounter
  extend ActiveSupport::Concern
  
  def sha
    @sha ||= github_pr.head.sha
  end
  
  def count_votes!
    instructions_found = process_comments
    post_instructions if !instructions_found && github_pr.state != "closed"
    update_state!
  end
    
  def update_state!
    if github_pr.state == "closed"
      if github_pr.merged == true
        state = "accepted"
      else
        state = "rejected"
      end
    else
      github_state = nil
      github_description = nil
      if blocked?
        state = "blocked"
        github_state = "failure"
        github_description = "The change is blocked."
      elsif agreed?
        state = "passed"
        github_state = "success"
        github_description = "The change is agreed."
      else
        state = "waiting"
        github_state = "pending"
        github_description = "The change is waiting for more votes; #{ENV["PASS_THRESHOLD"].to_i - score} more needed."
      end
      # Update github commit status
      set_build_status(github_state, github_description, "votebot/votes")
      # Check age
      if too_old?
        state = "dead"
        github_state = "failure"
        github_description = "The change has been open for more than #{ENV["MAX_AGE"]} days, and should be closed (age: #{age}d)."
      elsif too_new?
        state = "agreed" if state == "passed"
        github_state = "pending"
        github_description = "The change has not yet been open for #{ENV["MIN_AGE"]} days (age: #{age}d)."
      else
        github_state = "success"
        github_description = "The change has been open long enough to be merged (age: #{age}d)."
      end
      # Update github commit status
      set_build_status(github_state, github_description, "votebot/time")
    end
    # Store final state in DB
    update_attributes!(state: state)
  end

  def set_build_status(state, text, context)
    Octokit.create_status(ENV['GITHUB_REPO'], sha, state,
      target_url: "#{ENV['SITE_URL']}/proposals/#{number}",
      description: text,
      context: context)
  end

  def process_comments
    instructions_found = false
    comments = Octokit.issue_comments(ENV['GITHUB_REPO'], number)
    if sha
      commit = Octokit.pull_commits(ENV['GITHUB_REPO'], number).find{|x| x.sha == sha}
      cutoff = commit.commit.committer.date
    else
      cutoff = DateTime.new(1970)
    end
    comments.each do |comment|
      if comment.body =~ /<!-- votebot instructions -->/
        instructions_found = true
        next
      end
      user = User.find_or_create_by(login: comment.user.login)
      if user != proposer
        interaction = interactions.find_or_create_by!(user: user)
        if user.contributor
          if comment.body.contains_yes?
            next if comment.created_at < cutoff
            interaction.yes!
          end
          if comment.body.contains_no?
            interaction.no!
          end
          if comment.body.contains_block?
            interaction.block!
          end
        end
      end
    end
    instructions_found
  end

  def post_instructions
    Octokit.add_comment(ENV['GITHUB_REPO'], number, <<-EOF)
<!-- votebot instructions -->
This proposal is open for discussion and voting. If you are a [contributor](#{ENV['SITE_URL']}/users/) to this repository (and not the proposer), you may vote on whether or not it is accepted. 

## How to vote
Vote by entering one of the following symbols in a comment on this pull request. Only your last vote will be counted, and you may change your vote at any time until the change is accepted or closed.

|vote|symbol|type this|points|
|--|--|--|--|
|Yes|:white_check_mark:|`:white_check_mark:`|#{ENV["YES_WEIGHT"]}|
|No|:negative_squared_cross_mark:|`:negative_squared_cross_mark:`|#{ENV["NO_WEIGHT"]}|
|Block|:no_entry_sign:|`:no_entry_sign:`|#{ENV["BLOCK_WEIGHT"]}|

Proposals will be accepted and merged once they have a total of #{ENV["PASS_THRESHOLD"]} points when all votes are counted. Votes will be open for a minimum of #{ENV["MIN_AGE"]} days, but will be closed if the proposal is not accepted after #{ENV["MAX_AGE"]}.

Votes are counted [automatically here](#{ENV['SITE_URL']}/proposals/#{number}), and results are set in the merge status checks below.

## Changes

@#{proposer.login}, if you want to make further changes to this proposal, you can do so by [clicking on the pencil icons here](https://github.com/#{ENV['GITHUB_REPO']}/pull/#{number}/files). If a change is made to the proposal, no votes cast before that change will be counted, and votes must be recast.
EOF
  end

end