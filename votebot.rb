require 'sinatra/base'

class Votebot < Sinatra::Base
  
  get '/' do
    "Nothing to see here; visit <a href='http://openpolitics.org.uk'>openpolitics.org.uk</a> instead!"
  end
  
end