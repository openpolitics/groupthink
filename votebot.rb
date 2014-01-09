require 'sinatra/base'
require 'redis'

if ENV['RACK_ENV'] != "production" 
  ENV["REDISTOGO_URL"] = 'redis://localhost'
end

uri = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

class Votebot < Sinatra::Base
  
  get '/' do
    "Nothing to see here; visit <a href='http://openpolitics.org.uk'>openpolitics.org.uk</a> instead!"
  end
  
  post '/' do
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
    end
  end

  def on_issue_comment_created(json)
    issue = json['issue']
    if issue['state'] == 'open' && issue['pull_request']
      update_pr(issue['number'])
    end
  end

  def on_pull_request_opened(json)
    update_pr(json['number'])
  end
  
  def update_pr(number)
    puts number.inspect
  end

end