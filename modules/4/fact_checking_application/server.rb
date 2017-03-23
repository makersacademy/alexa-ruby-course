require 'sinatra'
require './lib/alexa/request'
require './lib/alexa/response'
require 'net/http'

post '/' do 
  alexa_request = Alexa::Request.new(request)

  number_fact = fetch_number_fact(alexa_request.slot_value("Number"), alexa_request.slot_value("FactType"))

  Alexa::Response.new(number_fact).to_json
end

def fetch_number_fact(number, fact_type)
  number_facts_uri = URI("http://numbersapi.com/#{ number }/#{ fact_type }")
  Net::HTTP.get(number_facts_uri)
end