require 'sinatra'
require './lib/alexa/response'

post '/' do  
  Alexa::Response.new.to_json
end