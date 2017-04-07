require 'sinatra'
require './lib/alexa/request'
require './lib/alexa/response'
require './lib/movie'

Handlers.add("AMAZON.StartOverIntent") do
  response_text = "OK, what movie would you like to know about?"
  
  Alexa::Response.build(response_text: response_text, start_over: true)
end

Handlers.add("MovieFacts") do
  movie = Movie.find(alexa_request.slot_value("Movie"))
  response_text = movie.plot_synopsis

  Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie.title })
end

Handlers.add("FollowUp") do
  movie = Movie.find(alexa_request.session_attribute("movieTitle"))

  response_text = movie.directors if alexa_request.slot_value("Role") == "directed"
  response_text = movie.cast_members if alexa_request.slot_value("Role") == "starred in"

  Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie.title })
end

### CONTROLLER CODE ###

post '/' do 
  Handlers.handle(Alexa::Request.new(request))
end