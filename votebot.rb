require 'sinatra/base'
require 'sinatra/partial'
require_relative 'environments'
require_relative 'models'

class Votebot < Sinatra::Base
  
  register Sinatra::Partial
  set :partial_template_engine, :erb
  enable :partial_underscores
  
  set :protection, :frame_options => 'ALLOW FROM http://openpolitics.org.uk'
  
  post '/update' do
    PullRequest.update_all_from_github!
    200
  end

  get '/' do
    @pull_requests = PullRequest.find_all.sort_by{|x| x.number.to_i}.reverse
    erb :index
  end
  
  get '/users/:login' do
    @user = User.find(params[:login])
    @pull_requests = PullRequest.find_all.sort_by{|x| x.number.to_i}.reverse
    @proposed, @pull_requests = @pull_requests.partition{|x| x.proposer['login'] == @user.login}
    @voted, @not_voted = @pull_requests.partition{|x| @user.voted.include?(x.number.to_i)}
    erb :user
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
      when 'passed', 'agreed'
        'success'
      when 'waiting'
        'warning'
      when 'blocked'
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