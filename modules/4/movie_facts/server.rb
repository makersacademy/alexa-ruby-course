require 'sinatra'
require './lib/alexa/request'
require './lib/alexa/response'
require 'imdb'

post '/' do 
  alexa_request = Alexa::Request.new(request)

  if alexa_request.intent_name == "ClearSession"
    return Alexa::Response.build("OK, what movie would you like to know about?", {}, true)
  end

  return respond_with_movie_plot_synopsis(alexa_request) if alexa_request.new_session?

  respond_with_movie_details(alexa_request)
end

def respond_with_movie_plot_synopsis(alexa_request)
  movie_list = Imdb::Search.new(alexa_request.slot_value("Movie")).movies
  movie = movie_list.first

  Alexa::Response.build(movie.plot_synopsis, { movieTitle: alexa_request.slot_value("Movie") })
end

def respond_with_movie_details(alexa_request)
  movie_title = alexa_request.session_attribute("movieTitle")
  movie_list = Imdb::Search.new(movie_title).movies
  movie = movie_list.first

  if alexa_request.slot_value("Role") == "directed"
    response_text = "#{movie_title} was directed by #{movie.director.join}"
  end

  if alexa_request.slot_value("Role") == "starred in"
    response_text = "#{movie_title} starred #{movie.cast_members.join(", ")}"
  end

  Alexa::Response.build(response_text, { movieTitle: movie_title })
end