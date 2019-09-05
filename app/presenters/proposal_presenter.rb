# frozen_string_literal: true

#
# Present a Proposal object for views
#
class ProposalPresenter < SimpleDelegator
  def initialize(proposal)
    @proposal = proposal
    super(proposal)
  end

  def activity_log
    activity = [description_to_activity_item] +
      @proposal.github_commits.map { |x| commit_to_activity_item(x) } +
      @proposal.github_comments.map { |x| comment_to_activity_item(x) }
    activity.compact.sort_by { |a| a[1][:time] }
  end

  private
    def commit_to_activity_item(commit)
      ["diff", {
        sha: commit[:sha],
        user: User.find_by(login: commit[:commit][:author][:name]),
        proposal: @proposal,
        original_url: @proposal.url,
        time: commit[:commit][:author][:date]
      }]
    end

    def description_to_activity_item
      return nil unless @proposal.description
      ["comment", {
        body: @proposal.description,
        user: @proposal.proposer,
        by_author: true,
        original_url: @proposal.url,
        time: @proposal.submitted_at
      }]
    end

    def comment_to_activity_item(comment)
      return nil if /votebot instructions/.match?(comment.body)
      ["comment", {
        body: comment.body,
        user: User.find_by(login: comment.user.login),
        by_author: (comment.user.login == @proposal.proposer.login),
        original_url: comment.html_url,
        time: comment.created_at
      }]
    end
end
