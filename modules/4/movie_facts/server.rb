require 'sinatra'
require './lib/alexa/request'
require './lib/alexa/response'
require 'imdb'

post '/' do 
  alexa_request = Alexa::Request.new(request)
  session = parsed_request["session"]

  if alexa_request.new_session?
    movie_list = Imdb::Search.new(alexa_request.slot_value("Movie")).movies
    movie = movie_list.first

    return Alexa::Response.build(movie.plot_synopsis, { movieTitle: alexa_request.slot_value("Movie") })
  end

  if alexa_request.intent_name == "ClearSession"
    return Alexa::Response.build("OK, what movie would you like to know about?", {}, true)
  end

  movie_title = session["attributes"]["movieTitle"]
  movie_list = Imdb::Search.new(movie_title).movies
  movie = movie_list.first

  role = parsed_request["request"]["intent"]["slots"]["Role"]["value"]

  if role == "directed"
    response_text = "#{movie_title} was directed by #{movie.director.join}"
  end

  if role == "starred in"
    response_text = "#{movie_title} starred #{movie.cast_members.join(", ")}"
  end

  Alexa::Response.build(response_text, { movieTitle: movie_title })
end