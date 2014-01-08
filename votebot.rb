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
    when "pull_request"
      on_pull_request(JSON.parse(params[:payload]))
    else
      400
    end
  end
  
  private
  
  def on_issue_comment(json)
    200
  end
  
  def on_pull_request(json)
    200
  end

end