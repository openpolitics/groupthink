# frozen_string_literal: true

#
# Methods for models that wrap around a GitHub issue.
#
module GithubIssue
  extend ActiveSupport::Concern

  def github_comments
    Octokit.issue_comments(ENV.fetch("GITHUB_REPO"), number)
  end

  private

    def github_add_comment(body)
      Octokit.add_comment(ENV.fetch("GITHUB_REPO"), number, body)
    end
end
