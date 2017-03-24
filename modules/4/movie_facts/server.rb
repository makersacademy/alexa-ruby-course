require 'sinatra'
require './lib/alexa/request'
require './lib/alexa/response'
require './lib/movie'

### CONTROLLER CODE ###

post '/' do 
  alexa_request = Alexa::Request.new(request)

  if alexa_request.intent_name == "ClearSession"
    response_text = "OK, what movie would you like to know about?"
    return Alexa::Response.build(response_text: response_text, end_session: true)
  end

  return respond_with_movie_plot_synopsis(alexa_request) if alexa_request.new_session?

  respond_with_movie_details(alexa_request)
end

### CONTROLLER CONVENIENCE METHODS ###

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