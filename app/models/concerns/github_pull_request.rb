# frozen_string_literal: true

#
# Methods for models that wrap around a GitHub pull request.
#
module GithubPullRequest
  extend ActiveSupport::Concern

  include GithubIssue

  def github_commits
    Octokit.pull_request_commits(Rails.application.config.groupthink[:github_repo], number)
  end

  def description
    github_pr.body
  end

  def submitted_at
    github_pr.created_at
  end

  def diff(sha = nil)
    sha ||= head_sha
    Octokit.compare(Rails.application.config.groupthink[:github_repo], base_sha, sha).files
  end

  def repo
    @repo ||= github_pr.head.repo.full_name
  end

  def branch
    @branch ||= github_pr.head.ref
  end

  def url
    "https://github.com/#{Rails.application.config.groupthink[:github_repo]}/pull/#{number}"
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

  def merge_pr!
    Octokit.merge_pull_request(Rails.application.config.groupthink[:github_repo], number)
    true
  rescue Octokit::MethodNotAllowed
    # PR couldn't be merged
    false
  end

  private
    def github_pr
      @github_pr ||= Octokit.pull_request(Rails.application.config.groupthink[:github_repo], number)
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
      Octokit.create_status(Rails.application.config.groupthink[:github_repo], sha, state.to_s,
        target_url: "#{Rails.application.config.groupthink[:site_url]}/proposals/#{number}",
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
      Octokit.add_comment(Rails.application.config.groupthink[:github_repo], number,
I18n.t("help.resubmit"))
      Octokit.close_pull_request(Rails.application.config.groupthink[:github_repo], number)
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
