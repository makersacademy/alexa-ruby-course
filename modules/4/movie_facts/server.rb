require 'sinatra'
require './lib/alexa/request'
require './lib/alexa/response'
require './lib/movie'

### CONTROLLER CODE ###

post '/' do 
  alexa_request = Alexa::Request.new(request)

  case alexa_request.intent_name
  when "AMAZON.StartOverIntent"
    respond_with_start_over
  when "MovieFacts"
    respond_with_movie_plot_synopsis(alexa_request)
  when "FollowUp"
    respond_with_movie_details(alexa_request)
  else
    respond_with_unknown
  end
end

### CONTROLLER CONVENIENCE METHODS ###

def respond_with_start_over
  response_text = "OK, what movie would you like to know about?"
  
  Alexa::Response.build(response_text: response_text, start_over: true)
end

def respond_with_movie_plot_synopsis(alexa_request)
  movie = Movie.find(alexa_request.slot_value("Movie"))
  response_text = movie.plot_synopsis

  Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie.title })
end

def respond_with_movie_details(alexa_request)
  movie = Movie.find(alexa_request.session_attribute("movieTitle"))

  response_text = movie.directors if alexa_request.slot_value("Role") == "directed"
  response_text = movie.cast_members if alexa_request.slot_value("Role") == "starred in"

  Alexa::Response.build(response_text: response_text, session_attributes: { movieTitle: movie.title })
end