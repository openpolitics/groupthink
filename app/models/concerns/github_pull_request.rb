# frozen_string_literal: true

#
# Methods for models that wrap around a GitHub pull request.
#
module GithubPullRequest
  extend ActiveSupport::Concern

  include GithubIssue

  def github_commits
    Octokit.pull_request_commits(ENV.fetch("GITHUB_REPO"), number)
  end

  def description
    github_pr.body
  end

  def submitted_at
    github_pr.created_at
  end

  def diff(sha = nil)
    sha ||= head_sha
    Octokit.compare(ENV.fetch("GITHUB_REPO"), base_sha, sha).files
  end

  def repo
    @repo ||= github_pr.head.repo.full_name
  end

  def branch
    @branch ||= github_pr.head.ref
  end

  def url
    "https://github.com/#{ENV.fetch("GITHUB_REPO")}/pull/#{number}"
  end

  def set_vote_build_status
    status = "groupthink/votes"
    if blocked?
      set_build_status(:failure, I18n.t("build_status.votes.blocked"), status)
    elsif passed?
      set_build_status(:success, I18n.t("build_status.votes.agreed"), status)
    else
      remaining_votes = Rules.pass_threshold - score
      set_build_status(:pending,
        I18n.t("build_status.votes.waiting", remaining: remaining_votes), status)
    end
  end

  def set_time_build_status
    status = "groupthink/time"
    if too_old?
      set_build_status(:failure,
        I18n.t("build_status.time.too_old", max_age: Rules.max_age, age: age), status)
    elsif too_new?
      set_build_status(:pending,
        I18n.t("build_status.time.too_new", min_age: Rules.min_age, age: age), status)
    else
      set_build_status(:success, I18n.t("build_status.time.success", age: age), status)
    end
  end

  def set_cla_build_status
    status = "groupthink/cla"
    if has_cla?
      if proposer_needs_to_sign_cla?
        set_build_status(:pending, I18n.t("build_status.cla.pending"), status)
      else
        set_build_status(:success, I18n.t("build_status.cla.accepted"), status)
      end
    end
  end

  def merge_pr!
    Octokit.merge_pull_request(ENV.fetch("GITHUB_REPO"), number)
    true
  rescue Octokit::MethodNotAllowed
    # PR couldn't be merged
    false
  end

  private
    def github_pr
      @github_pr ||= Octokit.pull_request(ENV.fetch("GITHUB_REPO"), number)
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
      Octokit.create_status(ENV.fetch("GITHUB_REPO"), sha, state.to_s,
        target_url: "#{ENV.fetch("SITE_URL")}/proposals/#{number}",
        description: text,
        context: context)
    end

    def pr_closed?
      github_pr.nil? || github_pr.state == "closed"
    end

    def pr_merged?
      github_pr.merged
    end

    def close_pr!
      Octokit.add_comment(ENV.fetch("GITHUB_REPO"), number, I18n.t("help.resubmit"))
      Octokit.close_pull_request(ENV.fetch("GITHUB_REPO"), number)
      true
    end

    def time_of_last_commit
      time = Time.zone.local(1970)
      if sha
        commit = github_commits.find { |x| x.sha == sha }
        time = commit.commit.committer.date
      end
      time
    end
end
