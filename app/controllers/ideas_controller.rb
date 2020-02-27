# frozen_string_literal: true

#
# Displays lists of submitted ideas, and individual idea pages.
#
class IdeasController < ApplicationController
  def index
    @ideas = Octokit.issues(ENV.fetch("GITHUB_REPO"), labels: "groupthink::idea")
  end

  def show
    @idea = Octokit.issue(ENV.fetch("GITHUB_REPO"), params[:id].to_i)
    raise ActiveRecord::RecordNotFound if @idea.nil?
    @activity = []
    @author = User.find_or_create_by!(login: @idea.user.login)
    # Add original description
    @activity << ["comment", {
      body: @idea[:body].presence || "*The author didn't add any more detail*",
      user: @author,
      by_author: true,
      original_url: @idea[:html_url],
      time: @idea.created_at
    }]
    # Add comments
    comments = Octokit.issue_comments(ENV.fetch("GITHUB_REPO"), params[:id].to_i)
    @activity.concat(comments.map { |comment|
      ["comment", {
        body: comment.body,
        user: User.find_or_create_by(login: comment.user.login),
        by_author: (@author.login == comment.user.login),
        original_url: comment.html_url,
        time: comment.created_at
      }]
    })
    # Remove any empty elements
    @activity.compact!
    # Sort by time
    @activity.sort_by! { |a| a[1][:time] }
  end
end
