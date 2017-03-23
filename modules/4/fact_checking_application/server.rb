require 'sinatra'
require './lib/alexa/request'
require './lib/alexa/response'
require './lib/number_fact'

post '/' do 
  alexa_request = Alexa::Request.new(request)

  number_fact = NumberFact.new(alexa_request.slot_value("Number"), alexa_request.slot_value("FactType"))

  Alexa::Response.new(number_fact.text).to_json
end