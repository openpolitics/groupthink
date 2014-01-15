require 'sinatra/base'
require_relative 'environments'
require_relative 'models'

class Votebot < Sinatra::Base
  
  post '/update' do
    PullRequest.update_all_from_github!
    200
  end

  get '/' do
    @pull_requests = PullRequest.find_all
    erb :index
  end
  
  get '/:number' do
    @pull_request = PullRequest.find(params[:number])
    erb :show
  end
  
  post '/:number/update' do
    @pull_request = PullRequest.find(params[:number])
    @pull_request.update_from_github!
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
      when 'passed'
        'success'
      when 'waiting'
        'warning'
      when 'blocked'
        'danger'
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
    when 'close'
      on_pull_request_closed(json)
    end
  end

  def on_issue_comment_created(json)
    issue = json['issue']
    if issue['state'] == 'open' && issue['pull_request']
      PullRequest.update_from_github!(issue['number'])
    end
  end

  def on_pull_request_opened(json)
    PullRequest.update_from_github!(json['number'])
    twitter.update("#{json['pull_request']['title']}: #{json['pull_request']['html_url']} #openpolitics")
  end
  
  def on_pull_request_closed(json)
    PullRequest.new(json['number']).delete!
  end
  
end