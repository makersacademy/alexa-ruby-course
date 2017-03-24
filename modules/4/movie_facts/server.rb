require 'sinatra'
require './lib/alexa/request'
require './lib/alexa/response'
require 'imdb'

post '/' do 
  alexa_request = Alexa::Request.new(request)
  session = alexa_request["session"]
  this_is_the_first_request = session["new"]

  if this_is_the_first_request
    requested_movie = parsed_request["request"]["intent"]["slots"]["Movie"]["value"]
    movie_list = Imdb::Search.new(requested_movie).movies
    movie = movie_list.first

    return Alexa::Response.build(movie.plot_synopsis, { movieTitle: requested_movie })
  end

  if parsed_request["request"]["intent"]["name"] == "ClearSession"
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