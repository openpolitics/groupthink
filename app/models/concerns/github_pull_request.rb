module GithubPullRequest
  extend ActiveSupport::Concern

  private

  def github_pr
    @github_pr ||= Octokit.pull_request(ENV['GITHUB_REPO'], number)
  end

  def head_sha
    github_pr["head"]["sha"]
  end
  
  def base_sha
    github_pr["base"]["sha"]
  end
  
  def sha
    @sha ||= github_pr.head.sha
  end
  
  def set_build_status(state, text, context)
    Octokit.create_status(ENV['GITHUB_REPO'], sha, state,
      target_url: "#{ENV['SITE_URL']}/proposals/#{number}",
      description: text,
      context: context)
  end

  def diff(sha = nil)
    sha ||= head_sha
    Octokit.compare(ENV['GITHUB_REPO'], base_sha, sha).files
  end

  def github_url
    "https://github.com/#{ENV['GITHUB_REPO']}/pull/#{number}"
  end
    
  def github_commits
    Octokit.pull_request_commits(ENV['GITHUB_REPO'], number)
  end

  def github_comments
    Octokit.issue_comments(ENV['GITHUB_REPO'], number)
  end

  def github_add_comment(body)
    Octokit.add_comment(ENV['GITHUB_REPO'], number, body)
  end

end