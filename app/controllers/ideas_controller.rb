# frozen_string_literal: true

#
# Displays lists of submitted ideas, and individual idea pages.
#
class IdeasController < ApplicationController
  before_action :get_idea, except: [:index]
  before_action :authenticate_user!, only: [:comment]

  def index
    @ideas = Octokit.issues(Rails.application.config.groupthink[:github_repo],
      labels: "groupthink::idea")
  end

  def show
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
    comments = Octokit.issue_comments(Rails.application.config.groupthink[:github_repo],
      params[:id].to_i)
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

  def comment
    user_github_connection.add_comment(Rails.application.config.groupthink[:github_repo],
      @idea["number"], params[:comment])
    redirect_to idea_path(@idea["number"])
  end

  private
    def get_idea
      @idea = Octokit.issue(Rails.application.config.groupthink[:github_repo], params[:id].to_i)
      raise ActiveRecord::RecordNotFound if @idea.nil?
    end
end
