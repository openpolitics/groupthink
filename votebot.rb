require 'sinatra/base'
require 'sinatra/partial'
require "sinatra/activerecord"
require "bugsnag"
require 'octokit'
require_relative 'app/models'

Bugsnag.configure do |config|
  config.api_key = ENV["BUGSNAG_API_KEY"]
end

Octokit.configure do |c|
  c.access_token = ENV['GITHUB_OAUTH_TOKEN']
end
Octokit.auto_paginate = true

class Votebot < Sinatra::Base
  
  set :views, Proc.new { File.join(root, "app", "views") }
  set :public_folder, Proc.new { File.join(root, "app", "assets") }
  
  register Sinatra::ActiveRecordExtension
    
  register Sinatra::Partial
  set :partial_template_engine, :erb
  enable :partial_underscores
  
  set :protection, :frame_options => 'ALLOW FROM http://openpolitics.org.uk'
  
  use Bugsnag::Rack
  enable :raise_errors
  
  post '/update' do
    User.update_all_from_github!
    Proposal.recreate_all_from_github!
    200
  end

  post '/webhook' do
    case env['HTTP_X_GITHUB_EVENT']
    when "issue_comment"
      on_issue_comment(JSON.parse(params[:payload]))
      200
    when "pull_request"
      on_pull_request(JSON.parse(params[:payload]))
      200
    else
      400
    end
  end
  
  private
  
  def on_issue_comment(json)
    case json['action']
    when 'created'
      on_issue_comment_created(json)
    end
  end
  
  def on_pull_request(json)
    case json['action']
    when 'opened'
      on_pull_request_opened(json)
    when 'closed'
      on_pull_request_closed(json)
    end
  end

  def on_issue_comment_created(json)
    issue = json['issue']
    if issue['state'] == 'open' && issue['pull_request']
      Proposal.create_from_github!(issue['number'])
    end
  end

  def on_pull_request_opened(json)
    Proposal.create_from_github!(json['number'])
  end
  
  def on_pull_request_closed(json)
    Proposal.find_or_create_by(number: json['number']).try(:close!)
  end
  
end