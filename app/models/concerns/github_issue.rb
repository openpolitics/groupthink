module GithubIssue
  extend ActiveSupport::Concern

  private

  def github_comments
    Octokit.issue_comments(ENV['GITHUB_REPO'], number)
  end

  def github_add_comment(body)
    Octokit.add_comment(ENV['GITHUB_REPO'], number, body)
  end

end