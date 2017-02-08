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
      required_agrees = ENV["PASS_THRESHOLD"].to_i
      github_state = nil
      github_description = nil
      votes = (agree.count * ENV["UPVOTE_WEIGHT"].to_i) + (abstain.count * ENV["ABSTAIN_WEIGHT"].to_i) + (disagree.count * ENV["DOWNVOTE_WEIGHT"].to_i)
      if votes < ENV["BLOCK_THRESHOLD"].to_i
        state = "blocked"
        github_state = "failure"
        github_description = "The change is blocked."
      elsif votes >= required_agrees
        state = "passed"
        github_state = "success"
        github_description = "The change is agreed."
      else
        state = "waiting"
        github_state = "pending"
        github_description = "The change is waiting for more votes; #{required_agrees - votes} more needed."
      end
      # Update github commit status
      Octokit.create_status(ENV['GITHUB_REPO'], sha, github_state,
        target_url: "https://votebot.openpolitics.org.uk/proposals/#{number}",
        description: github_description,
        context: "votebot/votes")
      # Check age
      if age >= ENV["MAX_AGE"].to_i
        state = "dead"
        github_state = "failure"
        github_description = "The change has been open for more than #{ENV["MAX_AGE"]} days, and should be closed."
      elsif age >= ENV["MIN_AGE"].to_i
        github_state = "success"
        github_description = "The change has been open long enough to be merged."
      else
        state = "agreed" if state == "passed"
        github_state = "pending"
        github_description = "The change has not yet been open for #{ENV["MIN_AGE"]} days."
      end
      # Update github commit status
      Octokit.create_status(ENV['GITHUB_REPO'], sha, github_state,
        target_url: "https://votebot.openpolitics.org.uk/proposals/#{number}",
        description: github_description,
        context: "votebot/time")
    end
    # Store final state in DB
    update_attributes!(state: state)
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
          case comment.body
          when /:thumbsup:|:\+1:|👍/
            next if comment.created_at < cutoff
            interaction.agree!
          when /:hand:|✋/
            interaction.abstain!
          when /:thumbsdown:|:\-1:|👎/
            interaction.disagree!
          end
        end
      end
    end
    instructions_found
  end

  def post_instructions
    Octokit.add_comment(ENV['GITHUB_REPO'], number, <<-EOF)
<!-- votebot instructions -->
This proposal is open for discussion and voting. If you are a [contributor](https://votebot.openpolitics.org.uk/users/) to this repository (and not the proposer), you may vote on whether or not it is accepted. 

## How to vote
Vote by entering one of the following symbols in a comment on this pull request. Only your last vote will be counted, and you may change your vote at any time until the change is accepted or closed.

|vote|symbol|type this|points|
|--|--|--|--|
|Agree|:thumbsup:|`:thumbsup:`|#{ENV["UPVOTE_WEIGHT"]}|
|Abstain|:hand:|`:hand:`|#{ENV["ABSTAIN_WEIGHT"]}|
|Block|:thumbsdown:|`:thumbsdown:`|#{ENV["DOWNVOTE_WEIGHT"]}|

Proposals will be accepted and merged once they have a total of #{ENV["PASS_THRESHOLD"]} points when all votes are counted. Votes will be open for a minimum of #{ENV["MIN_AGE"]} days, but will be closed if the proposal is not accepted after #{ENV["MAX_AGE"]}.

Votes are counted [automatically here](https://votebot.openpolitics.org.uk/proposals/#{number}), and results are set in the merge status checks below.

## Changes

If the proposer makes a change to the proposal, no votes cast before that change will be counted.
EOF
  end

end