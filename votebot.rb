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

  get '/' do
    @open_proposals = Proposal.open.sort_by{|x| x.number.to_i}.reverse
    @closed_proposals = Proposal.closed.sort_by{|x| x.number.to_i}.reverse
    erb :index
  end
  
  get '/users' do
    @users = User.all.order(:login)
    @contributors = @users.select{|x| x.contributor}
    @others = @users.select{|x| !x.contributor}
    erb :users
  end

  get '/users/:login' do
    @user = User.find_by_login(params[:login])
    @proposals = Proposal.all.sort_by{|x| x.number.to_i}.reverse
    @proposed, @proposals = @proposals.partition{|x| x.proposer == @user}
    @voted, @not_voted = @proposals.partition{|pr| @user.participating.where("last_vote IS NOT NULL").include? pr}
    @not_voted.reject!{|x| x.closed? }
    erb :user
  end
  
  get '/:number' do
    @proposal = Proposal.find_by(number: params[:number])
    if @proposal
      erb :show
    else
      404
    end
  end
  
  post '/:number/update' do
    @proposal = Proposal.find_by(number: params[:number])
    @proposal.update_from_github!
    redirect "/#{params[:number]}"
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
  
  helpers do
    def row_class(pr)
      case pr.state
      when 'passed', 'agreed', 'accepted'
        'success'
      when 'waiting'
        'warning'
      when 'blocked', 'dead', 'rejected'
        'danger'
      end
    end
    def user_row_class(state)
      case state
      when 'agree'
        'success'
      when 'abstain', 'participating'
        'warning'
      when 'disagree'
        'danger'
      else
        ''
      end
    end
    def state_image(state)
      case state
      when 'agree'
        "<img src='https://github.global.ssl.fastly.net/images/icons/emoji/+1.png?v5' title='Agree'/>"
      when 'abstain'
        "<img src='https://github.global.ssl.fastly.net/images/icons/emoji/hand.png?v5' title='Abstain'/>"
      when 'disagree'
        "<img src='https://github.global.ssl.fastly.net/images/icons/emoji/-1.png?v5' title='Disagree'/>"
      else
        ""
      end
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