module GithubPullRequest
  extend ActiveSupport::Concern
  
  include GithubIssue

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
  
  def github_repo
    @github_repo ||= github_pr.head.repo.full_name
  end
  
  def github_branch
    @github_branch ||= github_pr.head.ref
  end


  def set_build_status(state, text, context)
    Octokit.create_status(ENV['GITHUB_REPO'], sha, state,
      target_url: "#{ENV['SITE_URL']}/proposals/#{number}",
      description: text,
      context: context)
  end

  def github_diff(sha = nil)
    sha ||= head_sha
    Octokit.compare(ENV['GITHUB_REPO'], base_sha, sha).files
  end

  def github_url
    "https://github.com/#{ENV['GITHUB_REPO']}/pull/#{number}"
  end
    
  def github_commits
    Octokit.pull_request_commits(ENV['GITHUB_REPO'], number)
  end
  
  def pr_closed?
    github_pr.state == "closed"
  end

  def pr_merged?
    github_pr.merged
  end
  
  def merge_pr!
    Octokit.merge_pull_request(ENV['GITHUB_REPO'], number)
    true
  rescue Octokit::MethodNotAllowed
    # PR couldn't be merged
    false
  end
  
  def close_pr!
    Octokit.add_comment(ENV['GITHUB_REPO'], number, "Closed automatically: maximum age exceeded. Please feel free to resubmit this as a new proposal, but remember you will need to base any new proposal on the current policy text.")
    Octokit.close_pull_request(ENV['GITHUB_REPO'], number)
    true
  end

  def time_of_last_commit
    time = DateTime.new(1970)
    if sha
      commit = github_commits.find{|x| x.sha == sha}
      time = commit.commit.committer.date
    end
    time
  end

end
