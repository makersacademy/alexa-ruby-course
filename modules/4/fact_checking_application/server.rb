require 'sinatra'
require './lib/alexa/response'
require 'net/http'

post '/' do 
  parsed_request = JSON.parse(request.body.read)

  number = parsed_request["request"]["intent"]["slots"]["Number"]["value"]
  fact_type = parsed_request["request"]["intent"]["slots"]["FactType"]["value"]

  number_facts_uri = URI("http://numbersapi.com/#{ number }/#{ fact_type }")
  number_fact = Net::HTTP.get(number_facts_uri)

  Alexa::Response.new(number_fact).to_json
end