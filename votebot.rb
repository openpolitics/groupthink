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
      200
    when "pull_request"
      200
    else
      400
    end
  end
  
end