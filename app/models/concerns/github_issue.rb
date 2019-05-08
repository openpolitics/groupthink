# frozen_string_literal: true

#
# Methods for models that wrap around a GitHub issue.
#
module GithubIssue
  extend ActiveSupport::Concern

  #
  # Fetch comments from GitHub
  #
  # @return [Array] A list of comments
  #
  def github_comments
    Octokit.issue_comments(ENV.fetch("GITHUB_REPO"), number)
  end

  private

    #
    # Add a comment to the GitHub issue
    #
    # @param [String] body The text of the comment to add
    #
    def github_add_comment(body)
      Octokit.add_comment(ENV.fetch("GITHUB_REPO"), number, body)
    end
end
